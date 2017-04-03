class NewDealCardsBroadcastJob < ApplicationJob
  queue_as :default

  def perform(deal)
    I18n.available_locales.each do |locale|
      ActionCable.server.broadcast(
        "new_deal_user_#{deal.advisor.id}:cards_#{locale}",
        card: render_deal_card(deal, deal.advisor, locale),
        deal_id: deal.id
      )
      ActionCable.server.broadcast(
        "new_deal_user_#{deal.client.id}:cards_#{locale}",
        card: render_deal_card(deal, deal.client, locale),
        deal_id: deal.id
      )
    end
    ActionCable.server.broadcast(
      "user_#{deal.advisor.id}:notifications",
      notifications: render_user_notifications(deal.advisor)
    )
  end

  private

  def render_deal_card(deal, receiver, locale)
    I18n.with_locale(locale) do
      ApplicationController.render_with_signed_in_user(receiver, partial: 'deals/card', locals: { deal: deal, locale: locale})
    end
  end

  def render_user_notifications(receiver)
    ApplicationController.render_with_signed_in_user(receiver, partial: 'users/notifications')
  end
end
