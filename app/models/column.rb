class Column < ApplicationRecord
  belongs_to :board
  has_many :cards, -> { order(:position) }, dependent: :destroy

  acts_as_list scope: :board

  validates :name, presence: true
end
