class TakesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]  # if you want only logged-in users to post
  before_action :set_take, only: [:show, :edit, :update, :destroy]

  def index
    # Show the newest takes first, for example
    @takes = Take.order(created_at: :desc).includes(:user)
  end

  def show
  end

  def new
    @take = current_user.takes.build
  end

  def create
    @take = current_user.takes.build(take_params)
    if @take.save
      redirect_to @take, notice: "Take was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Only the author can edit, if you want that logic, you can check:
    # redirect_to takes_path unless @take.user == current_user
  end

  def update
    if @take.update(take_params)
      redirect_to @take, notice: "Take was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @take.destroy
    redirect_to takes_path, notice: "Take was successfully deleted."
  end

  private

  def set_take
    @take = Take.find(params[:id])
  end

  def take_params
    # Permit the body and the photo attachment
    params.require(:take).permit(:body, :photo)
  end
end
