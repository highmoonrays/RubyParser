require 'curb'
require 'nokogiri'
require 'csv'

puts 'Script started...'

def writeCSV(arr)
  CSV.open("./#{ARGV[1]}.csv", 'ab') do |csv|
    csv << arr
  end
end

def processPage(body)
  puts "#{body.xpath("count(//div[@class='product-container'])").to_i} items at this page."
  body.xpath("//ul[@id='product_list']//a[@class='product-name']").each do |item|
    parseProducts(item.xpath('./@href'))
  end
end

def parseProducts(url)
  http = Curl.get(url.to_s)
  body = Nokogiri::HTML(http.body_str)

  title = body.xpath("//h1[@class='product_main_name']/text()").to_s.strip!
  img = body.xpath("//img[@id='bigpic']/@src")
  options = body.xpath("//div[@class='attribute_list']/ul/li")
  if options.length > 0
    options.each do |option|
      name = "#{title} - #{option.xpath("./label/span[@class='radio_label']/text()")}"
      price = option.xpath("./label/span[@class='price_comb']/text()")
      writeCSV([name, price, img])
    end
  else
    price = body.xpath("//span[@id='our_price_display']/text()")
    if title.to_s.empty? || price.to_s.empty? || img.to_s.empty?
      puts "Broken link: #{url}"
    else
      writeCSV([title,price,img])
    end
  end
end

puts "Write headers to #{ARGV[1]}.csv"
writeCSV(['Name', 'Price', 'Image'])

page = 1
http = Curl.get(ARGV[0])
body = Nokogiri::HTML(http.body_str)

lastPage = body.xpath("//ul[contains(@class, 'pagination')]/li[position() = (last() - 1)]/a/span/text()").to_s

loop do
  puts "Process page #{page} from #{lastPage}."
  processPage(body)
  page += 1
  if page <= lastPage.to_i
    http = Curl.get("#{ARGV[0]}?p=#{page}")
    body = Nokogiri::HTML(http.body_str)
  else
    puts "Script finished at page #{page-1}."
    break
  end
end