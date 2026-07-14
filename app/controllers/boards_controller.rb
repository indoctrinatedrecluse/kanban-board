class BoardsController < ApplicationController
  def show
    @board = Board.includes(columns: { cards: :assignee }).first || DemoBoard.create!
    @users = User.order(:name)
    @card = Card.new(priority: "medium")
  end

  def clear
    @board = Board.first || DemoBoard.create!
    @board.columns.each do |column|
      column.cards.destroy_all
    end
    redirect_to root_path, notice: "Board cleared successfully"
  end
end
