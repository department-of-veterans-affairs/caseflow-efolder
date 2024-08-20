module BGSErrors
  class InvalidUsername < StandardError; end
  class InvalidStation < StandardError; end
  class InvalidApplication < StandardError; end
  class NoActiveStations < StandardError; end
  class NoCaseflowAccess < StandardError; end
  class StationAssertionRequired < StandardError; end
end
