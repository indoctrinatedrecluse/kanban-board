class ColumnsController < ApplicationController
  before_action :set_column, only: %i[show update]

  def show
    render partial: "columns/modal", locals: { column: @column }
  end

  def update
    @column.update!(column_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  private

  def set_column
    @column = Column.find(params[:id])
  end

  def column_params
    params.require(:column).permit(:name, :wip_limit)
  end
end
