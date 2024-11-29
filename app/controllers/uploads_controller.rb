class UploadsController < ApplicationController
  include ActiveStorage::SetCurrent

  def create
    file = params[:file]
    blob = ActiveStorage::Blob.create_and_upload! io: file, filename: file.original_filename, content_type: file.content_type
    @upload = Current.account.uploads_attachments.create! blob: blob
    render :create, status: :created, formats: :json
  end

  def show
    @attachment = ActiveStorage::Attachment.find_by! slug: "#{params[:slug]}.#{params[:format]}"
    expires_in 1.year, public: true
    redirect_to @attachment.url
  end
end
