class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def webhook
    endpoint_secret = ENV['STRIPE_ENDPOINT_SECRET']
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      @event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      # Invalid payload
      render status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      render status: 400
      return
    end

    @user = params[:account] && User.find_by( stripe_account_id: params[:account] )
    if @user.present?
      case @event.try(:type)

      when 'account.updated'
        payouts_enabled = @event.data.object.payouts_enabled
        charges_enabled = @event.data.object.charges_enabled
        if (payouts_enabled && charges_enabled)
          @user.pricing_enabled!
          retry_failed_payouts
        else
          @user.pricing_disabled!
        end

      when 'account.external_account.updated'
        status = @event.data.object.status
        @user.bank_invalid! if ["verification_failed", "errored"].include?(status)

      when 'payout.paid'
        retrieve_payout_deal
        if @deal.present? && @deal.payout_pending?
          @deal.payout_made!
          @deal.payout_made_at = DateTime.now
          @deal.save
        end

      when 'payout.failed'
        retrieve_payout_deal
        if @deal.present?
          @deal.payout_failed!
          DealMailer.deal_payout_failed(@deal).deliver_later
        end

      end
    end

    render status: 200
  end

  private

  def retrieve_payout_deal
    payout_id = @event.data.object.id
    payout = Stripe::Payout.retrieve(payout_id, {stripe_account: params[:account] })
    deal_id = payout.metadata.deal_id if payout.present?
    @deal = Deal.find(deal_id) if deal_id.present?
  end

  def retry_failed_payouts
    @user.advisor_deals_payout_failed.each do |deal|
      deal.payout_pending!
      StripePayoutJob.perform_later(deal)
    end
  end

end
