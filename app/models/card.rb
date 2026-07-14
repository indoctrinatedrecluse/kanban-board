class Card < ApplicationRecord
  belongs_to :column
  belongs_to :assignee, class_name: "User", optional: true

  acts_as_list scope: :column

  PRIORITIES = %w[low medium high urgent].freeze

  validates :title, presence: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true

  def label_list
    labels.to_s.split(",").map(&:strip).reject(&:blank?)
  end
end
