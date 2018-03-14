# GnuCash GetQuotes Workaround

## Introduction
Yahoo Finance recently (Nov 1, 2017) turned off its API that allowed users to get stock and mutual fund quotes.  That meant that any program that used Yahoo to get quotes would no longer be able to get updated prices.  By default GnuCash uses the perl module Finance::Quote to query Yahoo.

This script gets stock quotes from Google and updates GnuCash.  It is an ugly workaround.  Before you run this your first course of action should be to check out the Finance::Quote or GnuCash mailing lists to see if this problem has been solved in a proper manner.

The script works for me, but it is particular to my situation.

## Prerequisites
I have tested this script on exactly one configuration.  It may not work for you.

### You
- Have a Google account
- Request API credentials from Google
- Be able to restore a backup from GnuCash in case things go horribly wrong

### Environment
- Ubuntu 14.04
- Ruby 2.4.x
  - google-api-client
  - nokogiri
- GnuCash 2.6.1 running with XML backend

### GnuCash Data
- All commodities priced in USD
- All commodites of type NYSE, NASDAQ, or FUND

## Running

`ruby getquotes_google.rb` will read your commodities from your GnuCash file and create a Google Sheet.

`ruby getquotes_google.rb update_gnucash` will read your commodities from your GnuCash file, create a Google Sheet and update your GnuCash XML file.  To run this script you have to shut down GnuCash first.
