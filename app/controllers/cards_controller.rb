class CardsController < ApplicationController
  before_action :set_card, only: %i[update move]

  def create
    @column = Column.find(params[:column_id])
    @card = @column.cards.create!(card_params)

    redirect_to root_path
  end

  def update
    @card.update!(card_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def move
    column = Column.find(params.require(:column_id))
    position = params.require(:position).to_i

    @card.update!(column: column)
    @card.insert_at(position)

    head :ok
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:title, :description, :priority, :due_on, :estimate, :labels, :assignee_id)
  end
end
