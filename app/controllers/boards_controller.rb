class BoardsController < ApplicationController
  before_action :set_board, only: %i[edit update clear]

  def show
    @board = Board.includes(columns: { cards: :assignee }).first || DemoBoard.create!
    @users = User.order(:name)
    @card = Card.new(priority: "medium")
  end

  def edit
    render partial: "boards/settings_modal", locals: { board: @board }
  end

  def update
    @board.update!(board_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def clear
    @board.columns.each do |column|
      column.cards.destroy_all
    end
    redirect_to root_path, notice: "Board cleared successfully"
  end

  private

  def set_board
    @board = Board.includes(columns: :cards).first || DemoBoard.create!
  end

  def board_params
    params.require(:board).permit(:name, :description)
  end
end
