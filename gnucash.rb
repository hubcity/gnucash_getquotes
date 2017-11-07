require 'nokogiri'
require 'zlib'

class GnuCash

  def GnuCash.get_guids(number)
    cmd = "gnucash-make-guids #{number} 2> /dev/null"
    `#{cmd}`.split
  end

  def initialize(path)
    @doc = Nokogiri::XML(Zlib::GzipReader.open(GNUCASH_PATH).read)
    @pricedb = @doc.xpath('//gnc:pricedb')[0]
  end

  def has_lockfile?
    File.file?("#{GNUCASH_PATH}.LCK")
  end

  def get_tickers(space)
    @doc.xpath("//gnc:commodity[cmdty:space/text() = '#{space}']/cmdty:id/text()").map do |item|
      item.content
    end
  end

  def add_price(ticker, space, price, guid)
    unless price.is_number?
      print "Price for #{ticker} could not be found!\n"
      return
    end

    price = (price.to_f * 10000000).to_i
    date = Time.now.strftime("%Y-%m-%d %H:%M:%S %z")
    new_price = <<-NEW_PRICE
    <price>
      <price:id type="guid">#{guid}</price:id>
      <price:commodity>
        <cmdty:space>#{space}</cmdty:space>
        <cmdty:id>#{ticker}</cmdty:id>
      </price:commodity>
      <price:currency>
        <cmdty:space>ISO4217</cmdty:space>
        <cmdty:id>USD</cmdty:id>
      </price:currency>
      <price:time>
        <ts:date>#{date}</ts:date>
      </price:time>
      <price:source>Google</price:source>
      <price:type>last</price:type>
      <price:value>#{price}/10000000</price:value>
    </price>
    NEW_PRICE
    @pricedb.add_child(new_price)

    # Fix namespaces on added nodes to match gnucash XML
    @doc.xpath('//gnc:price').each do |node|
      node.namespace = nil
    end
  end

  def save
    fn = Zlib::GzipWriter.open(GNUCASH_PATH)
    fn.write(@doc.to_xml)
    fn.close()
  end

end
