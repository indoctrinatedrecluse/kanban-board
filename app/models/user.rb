class User < ApplicationRecord
  has_many :assigned_cards, class_name: "Card", foreign_key: :assignee_id, inverse_of: :assignee, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
