class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = Post.new
  end

  # def create
  #   @post = Post.new(post_params)
  #   @post.user = current_user # Associate the post with the current user

  #   if @post.save
  #     redirect_to @post, notice: 'Post was successfully created.'
  #   else
  #     render :new
  #   end
  # end

  def create
    @post = Post.new(post_params)
    @post.user = current_user

    if @post.save
      respond_to do |format|
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.js   # This will render create.js.erb
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.js   # This will render create.js.erb
      end
    end
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])

    if @post.update(post_params)
      redirect_to @post, notice: 'Post was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to posts_url, notice: 'Post was successfully destroyed.'
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end

end
