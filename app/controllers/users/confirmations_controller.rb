class Users::ConfirmationsController < Devise::ConfirmationsController

  private

  def after_resending_confirmation_instructions_path_for(resource_name)
    is_navigational_format? ? confirm_path : '/'
  end

  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource)
    welcome_path
  end
end
