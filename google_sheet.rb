require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"
require "ruby-progressbar"
require "typhoeus"

class GoogleSheetManager
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  APPLICATION_NAME = "Google Sheets API Ruby Quickstart".freeze
  CREDENTIALS_PATH = "credentials.json".freeze
  # The file token.yaml stores the user's access and refresh tokens, and is
  # created automatically when the authorization flow completes for the first
  # time.
  TOKEN_PATH = "token.yaml".freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  ##
  # Set up all the steps for processing, including validating the spreadsheet_id, and pulling
  # all the values we'll be operating on
  ##
  def initialize(spreadsheet_id)
    # Initialize the API
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize

    # Prints the names and majors of students in a sample spreadsheet:
    # https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
    # spreadsheet_id = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
    # range = "Insert your updates here!A3:E"
    range = "'Published factchecks'!A:Q"
    response = @service.get_spreadsheet_values spreadsheet_id, range
    puts "No data found." if response.values.empty?

    @spreadsheet_id = spreadsheet_id
    @values = response.values
  end

  ##
  # Run all the processing
  ##
  def process
    progressbar = ProgressBar.create(title: "Rows", total: @values.count, format: "%B | %c/%u | %p% | %E ")
    rows = []
    @values.each_with_index do |row, index|
      next if index == 0
      rows << [validate_url(row[9]), validate_url(row[10])]
      # row << validate_url(row[9]).to_s
      # row << validate_url(row[10]).to_s
      progressbar.increment
      break if index == 5
    end

    update_sheet(rows)
  end

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = ask "code?: "
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  ##
  # Check if the URL is valid by first checking if it passes a regex. Second, if it resolves to a 200
  ##
  def validate_url(url)
    results = /\A(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?\z/.match(url)
    return false if results.nil? || results.length == 0
    response = Typhoeus.get(url)
    return true if response.code == 200
    true
  end

  ##
  # Update the sheet with the go/no-go values
  ##
  def update_sheet(rows)
    a1_notation = "'Published factchecks'!R2:S#{rows.count + 1}"

    request_body = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
    value_range = Google::Apis::SheetsV4::ValueRange.new
    value_range.range = a1_notation
    value_range.major_dimension = "ROWS"
    value_range.values = rows

    request_body.data = [value_range]
    request_body.include_values_in_response = true
    request_body.value_input_option = "RAW"

    response = @service.batch_update_values(@spreadsheet_id, request_body)
    puts response.to_json
  end
end
