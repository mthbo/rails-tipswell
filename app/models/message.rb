class Message < ApplicationRecord
  belongs_to :user
  belongs_to :deal
end
