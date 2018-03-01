class DocumentCreator
  include ActiveModel::Model

  attr_accessor :manifest_source
  attr_writer :external_documents

  # C&P Exam (DBQ) sent back as both XML and PDF, ignore the XML 999981
  IGNORED_DOC_TYPES = %w[999981].freeze

  # documents of type Fiduciary should not be shown
  FIDUCIARY_DOC_TYPES = %w[
    552 600 607 601 602 546 603 604 545 605 606
    608 609 575 543 452 547 610 611 445 574 458
    535 612 614 442 595 644 615 616 541 540 456
    403 617 618 620 619 715 621 622 623 624 716
    625 626 628 629 630 631 443 632 633 634 635
    636 439 440 438 441 551 550 637 638 639 596
    640 642 643 511 402 538 645 646 647 648 544
    649 650 536 539 537 576 457 455 421 422 424
    594 425 426 169 404 454 128 429 430 431 432
    433 434 435 436 437 657 651 542 444 548
    549
  ].freeze

  # documents of types IRS/SSA, IVM and Financial Actions should not be shown
  RESTRICTED_VVA_DOC_TYPES = %w[
    804 807 808 809 810 811 812 813 814 815 816
    817 818 819 821 822 823 824 825 826 830 722
    723 724 725 726 727 728 729 752 753 831 832
    880 881
  ].freeze

  RESTRICTED_TYPES = IGNORED_DOC_TYPES + FIDUCIARY_DOC_TYPES + RESTRICTED_VVA_DOC_TYPES

  def create
    ManifestSource.transaction do
      # Re-create documents each time in order to use the latest versions
      # and if documents were deleted from VBMS
      manifest_source.records.delete_all
      external_documents.map do |document|
        Record.create_from_external_document(manifest_source, document)
      end
    end
  end

  # Override the getter to return only non-restricted documents
  def external_documents
    (@external_documents || []).reject { |document| RESTRICTED_TYPES.include?(document.type_id) || document.try(:restricted?) }
  end
end
