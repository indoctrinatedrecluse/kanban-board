class BoardsController < ApplicationController
  def show
    @board = Board.includes(columns: { cards: :assignee }).first || DemoBoard.create!
    @users = User.order(:name)
    @card = Card.new(priority: "medium")
  end
end
