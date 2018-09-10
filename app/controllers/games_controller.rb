class GamesController < ApplicationController
  before_action :set_game, only: [:show, :update, :destroy, :join, :move]

  # GET /games
  def index
    @games = Game.where(game_params).to_a
    render json: { games: index_games_json(@games)}
  end

  # GET /games/1
  def show
    render json: @game.game_json(true)
  end

  # POST /games
  def create
    if current_user.playing_or_waiting?
      return render json: {game: ["Current User already in Game"]}, status: :unprocessable_entity
    end
    @game = Game.new(user: [current_user])

    if @game.save
      render json: @game, status: :created, location: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /games/1
  def join
    error_json = {game: ["Game already full"]} if @game.user_ids.size > 1
    error_json ||= {user: ["User already in game"]} if current_user.playing_or_waiting?
    return render json: error_json, status: :bad_request if error_json.present?
    @game.users << current_user
    render status: :no_content
  end

  def move
    begin
      @game.move(params[:move], current_user)
      render status: :no_content
    rescue StandardError => ex
      return render json: {move: [ex.message]}, status: :bad_request
    end
  end

  # DELETE /games/1
  def destroy
    begin
      @game.destroy
      render status: :no_content
    rescue StandardError => ex
      return render json: {game: [ex.message]}, status: :unprocessable_entity
    end
  end

  private
    def index_games_json(games)
      games.map {|game| game.game_json}
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:game_id] || params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def game_params
      params.permit(:status)
    end
end
