# frozen_string_literal: true

# return all the BGS record data for a file number.
# this may return multiple BGS records, uniquely identified by participant_id

class VeteranFinder
  class MissingNumber < StandardError; end

  def initialize(bgs: nil)
    @bgs = bgs
  end

  def find(file_number)
    bgs_rec = bgs_record_for(file_number)

    return unless bgs_rec

    bgs_rec_numbers = bgs_numbers(bgs_rec)
    dupe_bgs_rec = find_duplicate_bgs_rec(bgs_rec_numbers)

    return [bgs_rec_numbers, bgs_numbers(dupe_bgs_rec)] if dupe_bgs_rec

    [bgs_rec_numbers]
  end

  def find_uniq_file_numbers(file_number)
    find(file_number).map { |vn| vn[:file].present? ? vn[:file] : vn["file_number"] }.compact.uniq
  end

  private

  def find_duplicate_bgs_rec(bgs_rec_numbers)
    # common enough in missing BGS data that we just return nil
    return if bgs_rec_numbers[:file].blank?

    if bgs_rec_numbers[:claim].present? && bgs_rec_numbers[:file].to_s == bgs_rec_numbers[:ssn].to_s
      # look again by claim number
      bgs_record_for(bgs_rec_numbers[:claim])
    elsif bgs_rec_numbers[:ssn].present? && bgs_rec_numbers[:file].to_s == bgs_rec_numbers[:claim].to_s
      # look again by ssn
      bgs_record_for(bgs_rec_numbers[:ssn])
    else
      error = MissingNumber.new("Found BGS file_number not equal to SSN or claim number: #{bgs_rec_numbers}")
      Raven.capture_exception(error)
      nil
    end
  end

  def bgs_numbers(bgs_rec)
    {
      ssn: bgs_rec[:soc_sec_number] || bgs_rec[:ssn],
      claim: bgs_rec[:claim_number],
      file: bgs_rec[:file_number],
      participant_id: bgs_rec[:ptcpnt_id]
    }.merge(bgs.parse_veteran_info(bgs_rec))
  end

  def bgs_record_for(file_number)
    bgs.fetch_veteran_info(file_number, parsed: false)
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
