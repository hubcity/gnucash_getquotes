#!/usr/bin/ruby

require 'google/apis/sheets_v4'
require_relative 'authorize'
require_relative 'gnucash'

CLIENT_SECRETS_PATH = File.join(Dir.home, 'client_secret.gnucashgetquotes.json')
GNUCASH_PATH = "../GnuCash.gnucash"
COMMODITY_SPACES = ["NYSE", "NASDAQ", "FUND"]
SHEETS_FILENAME = "GnuCash_GetQuotesHack"

class String
  def is_number?
    true if Float(self) rescue false
  end
end

# To actually save your changes in gnucash, you have to say so
update_gnucash = (ARGV[0] == "update_gnucash")

# Check to make sure lockfile does not exist if saving
gnucash = GnuCash.new(GNUCASH_PATH)
if (gnucash == nil)
  print "Could not find GnuCash file at #{GNUCASH_PATH}\n\n"
  exit
end
if (update_gnucash && gnucash.has_lockfile?)
  print "A GnuCash lockfile (.LCK) has been found.\n"
  print "GnuCash must be cleanly shut down before this program will run.\n\n"
  exit
end

# Get commodities from gnucash
commodities = []
COMMODITY_SPACES.each { |space|
  commodities += gnucash.get_tickers(space).map do |ticker|
    [ticker, space]
  end
}

# Google will let us look up prices if we put tickers in a spreadsheet
spreadsheet_values = commodities.each_with_index.map do |(ticker, space), i|
  [ticker, space, "=GoogleFinance(A#{i+1})"]
end

# Initialize the Sheets API
service = Google::Apis::SheetsV4::SheetsService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# TODO: Look for an existing spreadsheet before creating a new one
spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new({ properties: {'title': SHEETS_FILENAME }})
spreadsheet = service.create_spreadsheet(spreadsheet)

# Put values in spreadsheet and get results
value_range = Google::Apis::SheetsV4::ValueRange.new(values: spreadsheet_values)
updated_values = service.update_spreadsheet_value(spreadsheet.spreadsheet_id, "A1", value_range,
  { value_input_option: "USER_ENTERED",
    include_values_in_response: true,
    response_value_render_option: "FORMATTED_VALUE"}).updated_data.values


# Save
if (update_gnucash)
  # Update in-memory XML
  guids = GnuCash.get_guids(updated_values.length)
  updated_values.zip(guids) do |row|
    gnucash.add_price(*(row.flatten))
  end
end

print "\nA new spreadsheet has been created in Google Sheets called #{SHEETS_FILENAME}.\n"
print "It is no longer needed and can be safely deleted.\n"

if (update_gnucash)
  # Save to disk
  gnucash.save
  print "\nPrices have been updated.  Please restart GnuCash.\n"
else
  print "\nPrices in GnuCash have NOT been updated!\n"
  print "Please run the program again with the argument update_gnucash to update GnuCash.\n"
end
print "\n"
