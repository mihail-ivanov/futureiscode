class EventsController < ApplicationController
  respond_to :html

  before_filter :authenticate_speaker!, only: [:new, :create, :edit, :update]
  before_filter :authenticate_school!, only: [:approve, :unapprove]

  def index
    current_member = current_speaker || current_school
    @own_events = current_member.events.newest_first if current_member
    @events = Event.newest_first
  end

  def map
    @events = Event
      .newest_first
      .includes(:school)
      .select(&:geocoded?)
  end

  def new
    @event = Event.new default_event_params
  end

  def create
    @event = current_speaker.events.create event_params

    if @event.persisted?
      ApplicationMailer.new_event(@event).deliver_later
    end

    flash[:notice] = 'Събитието ви е създадено успешно и очаква преглед и одобрение от лицето за контакт в учебното заведение.'

    respond_with @event
  end

  def show
    @event = Event.find params[:id]
    @title = I18n.t('site.title', title: @event.name_or_default)
    @page_image = @event.cover_image.url(:large) if @event.cover_image.present?
    @page_description = @event.short_description
  end

  def edit
    @event = current_speaker.events.find params[:id]
  end

  def update
    @event = current_speaker.events.find params[:id]
    @event.update_attributes event_params

    respond_with @event
  end

  def approve
    event = current_school.events.find params[:id]
    event.update_attributes approved: true

    if event.errors.none?
      ApplicationMailer.event_approved(event).deliver_later
    end

    flash[:notice] = 'Събитието е одобрено.'

    redirect_to event
  end

  def unapprove
    event = current_school.events.find params[:id]
    event.update_attributes approved: false

    if event.errors.none?
      ApplicationMailer.event_reverted_to_pending(event).deliver_later
    end

    flash[:notice] = 'Събитието е върнато в състояние на очакващо потвърждение.'

    redirect_to event
  end

  private

  def event_params
    params.require(:event).permit(
      :school_id,
      :date,
      :name,
      :url,
      :public_email,
      :cover_image,
      :delete_cover_image,
      :details
    )
  end

  def default_event_params
    params
      .fetch(:event, {})
      .permit(:school_id)
      .merge(public_email: current_speaker.email, date: 1.week.from_now.to_date)
  end
end
