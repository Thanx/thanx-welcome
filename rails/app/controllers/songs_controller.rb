class SongsController < ApplicationController
  before_filter :authenticate

  # GET /users/:user_id/songs
  def index
    if params[:search].blank?
      @songs = RubyTunes::Track.all[0,50].map(&:properties)
    else
      @songs = RubyTunes::Track.search(params[:search])[0,50].map(&:properties)
    end
    @user = User.find(params[:user_id])
    @selections = @user.songs.map do |song|
      RubyTunes::Track.new(id: song.track_id).properties.merge(
        song_id:  song.id,
        start_at: song.start_at,
        end_at:   song.end_at
      )
    end
  end

  # POST /users/:user_id/songs
  def create
    user = User.find(params[:user_id])
    case params[:type]
    when 'remove'
      user.songs.where(track_id: params[:track_id]).destroy_all
    when 'add'
      user.songs.create(track_id: params[:track_id])
    end
    redirect_to :back
  end

  # PATCH /users/:user_id/songs/:id
  def update
    user = User.find(params[:user_id])
    song = user.songs.find_by_id(params[:id]) if user.present?
    song.update_attributes(
      start_at: params[:start_at],
      end_at:   params[:end_at]
    ) if song.present?
    redirect_to :back
  end

  # GET /users/:user_id/songs/:id
  def show
    redirect_path = user_songs_path(user_id: params[:user_id])
    song = Song.find(params[:id])
    Resque.enqueue(MusicJob, song_id: song.id)
    info = RubyTunes::Track.new(id: song.track_id).properties
    redirect_to redirect_path, notice: "Previewing #{info[:name]} by #{info[:artist]}"
  end

end
