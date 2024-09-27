# frozen_string_literal: true

class Api::V2::ManifestsController < Api::V2::ApplicationController
  # Need this as a before action since it gates access to these controller methods
  before_action :veteran_file_number, only: [:start, :refresh]

  def start
    return if performed?

    manifest = if FeatureToggle.enabled?(:use_ce_api) 
                 Manifest.includes(:sources, :records).find_or_create_by_user(user: current_user, file_number: veteran_file_number)
               else
                 Manifest.includes(:sources, :records).find_or_create_by_user(user: current_user, file_number: file_number)
               end

    manifest.start!
    render json: json_manifests(manifest)
  end

  def refresh
    manifest = if FeatureToggle.enabled?(:use_ce_api) 
                 Manifest.includes(:sources, :records).find_or_create_by_user(user: current_user, file_number: veteran_file_number)
               else
                 Manifest.find(params[:id])
               end

    return record_not_found if manifest.blank?
    return sensitive_record unless manifest.files_downloads.find_by(user: current_user)

    manifest.start!
    render json: json_manifests(manifest)
  end

  def progress
    files_download = nil
    distribute_reads do
      files_download ||= FilesDownload.find_with_manifest(manifest_id: params[:id], user_id: current_user.id)
    end

    return record_not_found unless files_download

    render json: json_manifests(files_download.manifest)
  end

  def history
    render json: recent_downloads, each_serializer: Serializers::V2::HistorySerializer
  end

  private

  def veteran_file_number
    @veteran_file_number ||= verify_veteran_file_number
  end

  def verify_veteran_file_number
    # The frontend may not have set this value (needed by parent's verify_veteran_file_number)
    # but we are still able to determine it here in the child using the manifest
    if request.headers["HTTP_FILE_NUMBER"].blank?
      if params[:id].present?
        manifest = Manifest.find(params[:id])
        request.headers["HTTP_FILE_NUMBER"] = manifest.file_number
      end
    end

    super
  end

  def json_manifests(manifest)
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def recent_downloads
    @recent_downloads ||= distribute_reads { current_user.recent_downloads.to_a }
  end
end
