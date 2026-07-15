class CardsController < ApplicationController
  before_action :set_card, only: %i[show update move duplicate destroy]

  def show
    @users = User.order(:name)
    render partial: "cards/modal", locals: { card: @card, users: @users }
  end

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

  def duplicate
    target_column = Column.find(params.require(:target_column_id))
    @new_card = @card.dup
    @new_card.column = target_column
    @new_card.title = "#{@card.title} (copy)"
    @new_card.save!
    @new_card.insert_at(target_column.cards.count)

    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "cards/card", locals: { card: @new_card, users: User.order(:name) } }
    end
  end

  def destroy
    @card.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@card) }
      format.html { redirect_to root_path, notice: "Card was successfully destroyed." }
    end
  end

  private

  def set_card
    @card = Card.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:title, :description, :priority, :due_on, :estimate, :labels, :assignee_id)
  end
end