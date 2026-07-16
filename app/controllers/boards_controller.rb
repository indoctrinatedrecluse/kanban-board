class BoardsController < ApplicationController
  before_action :set_board, only: %i[edit update clear assignees add_assignee remove_assignee]

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

  def assignees
    @users = User.order(:name)
    render partial: "boards/assignees_modal", locals: { board: @board, users: @users }
  end

  def add_assignee
    User.find_or_create_by(name: params[:name]) do |user|
      user.email = "test-#{SecureRandom.hex(4)}@example.com"
    end
    @users = User.order(:name)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("assignees_modal", partial: "boards/assignees_modal", locals: { board: @board, users: @users }),
          turbo_stream.replace("board_stats", partial: "boards/stats", locals: { board: @board, users: @users })
        ]
      end
      format.html { redirect_to root_path }
    end
  end

  def remove_assignee
    User.find(params[:id]).destroy
    @users = User.order(:name)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("assignees_modal", partial: "boards/assignees_modal", locals: { board: @board, users: @users }),
          turbo_stream.replace("board_stats", partial: "boards/stats", locals: { board: @board, users: @users })
        ]
      end
      format.html { redirect_to root_path }
    end
  end

  private

  def set_board
    @board = Board.includes(columns: :cards).first || DemoBoard.create!
  end

  def board_params
    params.require(:board).permit(:name, :description)
  end
end
