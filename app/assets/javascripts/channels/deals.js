$(document).ready(function() {

  var $deal = $("#deal-page");

  if ( $deal.length > 0 ) {

    var currentUserId = parseInt($("#my-navbar-logged").attr('data-user-id'));
    var dealId = parseInt($deal.attr('data-deal-id'));

    subcsribeToMessagesChannel(dealId, currentUserId);
    subcsribeToDealStatusChannel(dealId);

    typeMessage(dealId);
    submitMessage();

  }

});


function subcsribeToMessagesChannel(dealId, currentUserId) {

  App['deal' + dealId + ':messages_' + I18n.locale] = App.cable.subscriptions.create({channel: 'MessagesChannel', deal_id: dealId, locale: I18n.locale}, {
    received: function(data) {
      if (data.state === "typing" && currentUserId !== data.user_id) {
        $('#message-typing').removeClass("hide");
      } else if (data.state === "stop_typing" && currentUserId !== data.user_id) {
        $('#message-typing').addClass("hide");
      } else if (data.state === "sending") {
        var $new_message = $(data.message).hide();
        if ((data.target === "message") && (currentUserId !== data.user_id)) {
          $new_message.removeClass("message-right");
          $new_message.removeClass("message-yellow");
          $new_message.removeClass("message-green");
          $new_message.addClass("message-left");
        }
        $('#message-typing').before($new_message);
        $new_message.show();
        scrollConversation();
      }
    },

    type: function(dealId, state) {
      this.perform('type', { deal_id: dealId, state: state });
    }

  });

};


function subcsribeToDealStatusChannel(dealId) {

  App['deal' + dealId + ':status_'] = App.cable.subscriptions.create({channel: 'DealStatusChannel', deal_id: dealId, locale: I18n.locale}, {
    received: function(data) {
      if (data.status !== undefined) { $('#deal-status-panel').html(data.status); }
      if (data.info !== undefined) { $('#deal-info-panel').html(data.info); }
      if (data.actions !== undefined) { $('#deal-actions-panel').html(data.actions); }
      if (data.reviews !== undefined) { $('#deal-reviews-panel').html(data.reviews); }
      if (data.video_call !== undefined) { $('#video-call').html(data.video_call); }
      if (data.messages_disabled === true) {
        $('#message_content').attr('placeholder', I18n.t('messages.form.messages_disabled'));
        $('#message_content').prop('disabled', true);
        $('#new_message button').prop('disabled', true);
      }
      propositionToggle();
    },

  });

}


function typeMessage(dealId) {
  $('#message_content').focusin(function() {
    App['deal' + dealId + ':messages_' + I18n.locale].type(dealId, "typing");
  });
  $('#message_content').focusout(function() {
    App['deal' + dealId + ':messages_' + I18n.locale].type(dealId, "stop_typing");
  });
}

function submitMessage() {
  $('#message_content').on('keyup', function(event) {
    if (event.keyCode === 13 && !event.shiftKey && !isMobile()) {
      $('#submit_message').click();
    } else {
      $('#message_content')[0].style.height = $('#message_content')[0].scrollHeight+'px';
    }
  });
  $("#new_message").on('ajax:beforeSend', function() {
    $('#message_content').val("");
    $('#message_content')[0].style.height = "40px";
  });
}
