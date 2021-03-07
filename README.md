# Covid fact check cleaner
A cleaner for covid fact check data put together by the IFCN.

**Note** This uses a private Google Sheet for it's data source, so if you're looking at this it's almost certainly not what you actually want, and should just move on.

## Setup
1. Create a `credentials.json` file
1. Follow the setup guide on the Google Sheet's Ruby documentation to create this file.
1. Run `ruby cleaner.rb [id of sheet]` to clean it all.
