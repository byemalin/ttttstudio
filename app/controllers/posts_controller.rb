class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :user_posts]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]

  def index
    # @posts = Post.all
    @posts = Post.order(created_at: :desc)
  end

  def show
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: 'Post was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: 'Post was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @post = Post.find(params[:id])
    if @post.user == current_user
      @post.destroy
      Rails.logger.debug "Post destroyed successfully"
      redirect_to posts_url, notice: 'Post was successfully deleted.'
    else
      Rails.logger.debug "Unauthorized delete attempt"
      redirect_to posts_url, alert: 'You are not authorized to delete this post.'
    end
  end

  def user_posts
    @user = User.find(params[:id])
    @posts = @user.posts.order(created_at: :desc)
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :city, :country, images: [])
  end

  def authorize_user!
    redirect_to root_path, alert: "You are not authorized to perform this action." unless @post.user == current_user
  end

end
