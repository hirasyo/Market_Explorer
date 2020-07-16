class PagesController < ApplicationController
  def index
  end

  def search
    @result_all = []
    @result_count = {}

    # 各種サイトのチェックに応じてデータを持ってくる
    if params["yahoo"]
      # ヤフオクのURLからhtml情報を抽出
      @html,@charset = search_html(url_yahoo(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_yahoo = Nokogiri::HTML.parse(@html, nil, @charset)
      # 解析オブジェクトから必要な情報を抽出
      get_info_yahoo(@result_yahoo)

    end

    if params["mercari"]
      # メルカリのURLからhtml情報を抽出
      @html = search_html_mercari(url_mercari(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_mercari = Nokogiri::HTML.parse(@html, nil, 'utf-8')
      # 解析オブジェクトから必要な情報を抽出
      get_info_mercari(@result_mercari)

    end

    if params["jimoty"]
      # ジモティーのURLからhtml情報を抽出
      @html,@charset = search_html(url_jimoty(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_jimoty = Nokogiri::HTML.parse(@html, nil, @charset)
      # 解析オブジェクトから必要な情報を抽出
      get_info_jimoty(@result_jimoty)

    end

    if params["rakuma"]
      # ラクマのURLからhtml情報を抽出
      @html,@charset = search_html(url_rakuma(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_rakuma = Nokogiri::HTML.parse(@html, nil, @charset)
      # 解析オブジェクトから必要な情報を抽出
      get_info_rakuma(@result_rakuma)

    end

    if params["rakuten"]
      # 楽天市場のURLからhtml情報を抽出
      @html,@charset = search_html_rakuten(url_rakuten(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_rakuten = Nokogiri::HTML.parse(@html, nil, @charset)
      # 解析オブジェクトから必要な情報を抽出
      get_info_rakuten(@result_rakuten)

    end

    if params["hardoff"]
      # HardOffのURLからhtml情報を抽出
      @html,@charset = search_html(url_hardoff(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_hardoff = Nokogiri::HTML.parse(@html, nil, @charset)
      # 解析オブジェクトから必要な情報を抽出
      get_info_hardoff(@result_hardoff)

    end

    if params["wowma"]
      # Wowma!のURLからhtml情報を抽出
      @html = search_html_wowma(url_wowma(params[:keyword]))
      # 抽出したhtmlをパース(解析)してオブジェクトを作成
      @result_wowma = Nokogiri::HTML.parse(@html,nil, 'utf-8')
      logger.debug(@result_wowma)
      logger.debug("Wowmaのリザルト")
      # 解析オブジェクトから必要な情報を抽出
      get_info_wowma(@result_wowma)

    end

    #各種sort
    result_sort(@result_all)

    render partial: 'ajax_partial', locals: { :result_all => @result_all, :result_count => @result_count} and return

  end

  private

    def url_yahoo(keyword)
      "https://auctions.yahoo.co.jp/search/search?p=#{keyword}"
    end

    def url_mercari(keyword)
      "https://www.mercari.com/jp/search/?keyword=#{keyword}"
    end

    def url_jimoty(keyword)
      "https://jmty.jp/all/sale?keyword=#{keyword}"
    end

    def url_rakuma(keyword)
      "https://fril.jp/search/#{keyword}"
    end

    def url_rakuten(keyword)
      "https://search.rakuten.co.jp/search/mall/#{keyword}/?s=4"
#      "https://search.rakuten.co.jp/search/mall/#{keyword}/?used=1"
    end

    def url_hardoff(keyword)
      "https://netmall.hardoff.co.jp/search/?q=#{keyword}&p=1&pl=60"
    end

    def url_wowma(keyword)
      "https://wowma.jp/itemlist?e_scope=O&at=FP&non_gr=ex&spe_id=c_act_sc01&e=tsrc_topa_v&ipp=40&keyword=#{keyword}&categ_id=80"
    end

#    def url_daikokuya(keyword)
#      keyword_toutf8 = NKF.nkf('-W -s',keyword)
#      "https://www.daikokuya78.com/shop/goods/search.aspx?keyword=#{keyword}&search.x=0&search.y=0"
#    end

    def search_html(url)
      charset = nil
      search_url = URI.encode url
      html = open(search_url) do |f|
        charset = f.charset # 文字種別を取得
        f.read # htmlを読み込んで変数htmlに渡す
      end
      return html,charset
    end

    def search_html_mercari(url)
      opt = {}
      opt['User-Agent'] = 'Ruby'
      opt['Accept-Encoding'] = 'deflate'
      opt['Accept-Language'] = 'ja,en-US;q=0.9,en;q=0.8'
      search_url = URI.encode url
      html = open(search_url, opt) do |f|# htmlを読み込んで変数htmlに渡す
        f.read
      end
      return html
    end

    def search_html_rakuten(url)
      charset = nil
      search_url = URI.encode url
      html = open(search_url, "User-Agent"=>"Ruby") do |f|
        charset = f.charset # 文字種別を取得
        f.read # htmlを読み込んで変数htmlに渡す
      end
      return html,charset
    end

    def search_html_wowma(url)
      search_url =  url.encode("shift_jis")
      search = URI.encode search_url
      html = open(search).read # htmlを読み込んで変数htmlに渡す
      return html
    end

    def get_info_yahoo(result)
      get_count = 0

      result.xpath('//div[@class="Products__list"]/ul/li[@class="Product"]').each do |node|
        
        sale_now = true
        price_only_number = node.css('span.u-textRed').inner_text.gsub(/\¥|\,|\s|円/,"") #数値だけのお値段
        # 画面上の条件指定と合致するもののみ表示対象とする
        data_jugde(sale_now, price_only_number)
        if @get_info_this_data
          @temp_result = {}
            # 各種情報の取得
          @temp_result.store("img", node.css('img').attribute('src').value)
          @temp_result.store("link", node.css('a').attribute('href').value)
          @temp_result.store("name", node.css('h3').inner_text)
          @temp_result.store("price", node.css('span.u-textRed').inner_text.gsub(/\¥|\s/,""))
          @temp_result.store("target", "ヤフオク")
          @temp_result.store("sold_out", false)

          #Sort用のステータス
          @temp_result.store("for_sort_price", price_only_number)
          @result_all.push(@temp_result)
          get_count += 1
        end
      end
      @result_count.store("yahoo",get_count)

    end

    def get_info_mercari(result)
      get_count = 0
      products_none = result.xpath('//p[@class="search-result-description"]').present?
      unless products_none #商品がない場合は余計な解析を行わないようにする

        result.xpath('//section[@class="items-box"]').each do |node|

          sale_now = !node.css('figcaption').present?  #このCSSセレクタがヒットする商品は売り切れている = ヒットしない商品は販売中（sale now!）
          price_only_number = node.css('div.items-box-price').inner_text.gsub(/\¥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)
          if @get_info_this_data
            @temp_result = {}
              # 各種情報の取得
            @temp_result.store("img", node.css('img').attribute('data-src').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('h3').inner_text)
            @temp_result.store("price", node.css('div.items-box-price').inner_text.gsub(/\¥|\s/,"") + '円')
            @temp_result.store("target", "メルカリ")
            # 品切れか否か
            if sale_now
              @temp_result.store("sold_out", false)
            else
              @temp_result.store("sold_out", true)
            end

            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
      end
      @result_count.store("mercari",get_count)

    end

    def get_info_jimoty(result)
      get_count = 0

      # products_none = result.xpath('//div[@id="not_found_condition"]').present?
      # unless products_none #商品がない場合は余計な解析を行わないようにする

        result.xpath('//div[@class="p-articles-list js-articles-list"]/ul/li').each do |node|

          sale_now = !node.css('img.close').present?  #このCSSセレクタがヒットする商品は売り切れている = ヒットしない商品は販売中（sale now!）
          price_only_number = node.css('div[@class="p-item-most-important"]').inner_text.gsub(/\n|\¥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)

          if @get_info_this_data
            @temp_result = {}
            # 各種情報の取得
            @temp_result.store("img", node.css('img').attribute('src').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('h2').inner_text.gsub(/\n/,""))
            @temp_result.store("price", node.css('div[@class="p-item-most-important"]').inner_text.gsub(/\n/,""))
            @temp_result.store("target", "ジモティー")
            # 品切れか否か
            if sale_now
              @temp_result.store("sold_out", false)
            else
              @temp_result.store("sold_out", true)
            end

            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
      # end
      @result_count.store("jimoty",get_count)

    end

    def get_info_rakuma(result)
      get_count = 0
      products_none = result.xpath('//div[@class="nohit"]').present?
      unless products_none

        result.xpath('//div[@class="item"]').each do |node|

          sale_now = !node.css('div.item-box__soldout_ribbon').present?  #このCSSセレクタがヒットする商品は売り切れている = ヒットしない商品は販売中（sale now!）
          price_only_number = node.css('p.item-box__item-price').inner_text.gsub(/\n|\￥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)
          if @get_info_this_data
            @temp_result = {}
            # 各種情報の取得
            @temp_result.store("img", node.css('img').attribute('data-original').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('a.link_search_title').inner_text.gsub(/\n|^\s+|\s+$/,""))
            @temp_result.store("price", node.css('p.item-box__item-price').inner_text.gsub(/￥/,"") + "円")
            @temp_result.store("target", "ラクマ")
            # 品切れか否か
            if sale_now
              @temp_result.store("sold_out", false)
            else
              @temp_result.store("sold_out", true)
            end

            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
      end
      @result_count.store("rakuma",get_count)

    end

    def get_info_rakuten(result)
      get_count = 0
      products_none = result.xpath('//div[@class="dui-container sorry _centered"]').present?
      unless products_none

        result.xpath('//div[@class="dui-card searchresultitem"]').each do |node|

          sale_now = true
          price_only_number = node.css('span.important').inner_text.gsub(/\n|\¥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)
          if @get_info_this_data
            @temp_result = {}
            # 各種情報の取得
            @temp_result.store("img", node.css('img._verticallyaligned').attribute('src').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('h2/a').attribute('title').value)
            @temp_result.store("price", node.css('span.important').inner_text)
            @temp_result.store("target", "楽天市場")

            @temp_result.store("sold_out", false) #一律False
            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
      end
      @result_count.store("rakuten",get_count)

    end

    def get_info_hardoff(result)
      get_count = 0
      products_none = result.xpath('//span[@class="p-formSection__errorText"]').present?
      unless products_none

        result.xpath('//div[@class="p-goods__item p-goods__item--with-cart-btn"]').each do |node|

          # 今（20200716）は下記のCSSポインタは新着かどうかをみるのに使うっぽい？
          # とりあえず全部売っていることにしよう
          # sale_now = !node.css('ul.p-goods__status').present?  #このCSSセレクタがヒットする商品は売り切れている = ヒットしない商品は販売中（sale now!）
          sale_now = true;
          price_only_number = node.css('p.p-goods__price').inner_text.gsub(/\n|\¥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)
          if @get_info_this_data
            @temp_result = {}
            # 各種情報の取得
            @temp_result.store("img", node.css('img').attribute('src').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('span.p-goods__nameClamp').inner_text)
            @temp_result.store("price", node.css('p.p-goods__price').inner_text)
            @temp_result.store("target", "HardOff")
            # 品切れか否か
            if sale_now
              @temp_result.store("sold_out", false)
            else
              @temp_result.store("sold_out", true)
            end

            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
      end
      @result_count.store("hardoff",get_count)

    end

    # Wowmaは直接ページで検索しないと結果が０件になるみたい？検索対象から外す
    def get_info_wowma(result)
      get_count = 0
      pre_url = "https://wowma.jp"
#      products_none = result.xpath('').present? #何か指定するとエラー。。。意味わからん
#      unless products_none

        result.xpath('//div[@class="searchListingItems "]/ul').each do |node|

          sale_now = true
          price_only_number = node.css('p.price').inner_text.gsub(/\n|\¥|\,|\s|円/,"") #数値だけのお値段
          # 画面上の条件指定と合致するもののみ表示対象とする
          data_jugde(sale_now, price_only_number)
          if @get_info_this_data
            @temp_result = {}
            # 各種情報の取得
            @temp_result.store("img", node.css('img').attribute('src').value)
            @temp_result.store("link", node.css('a').attribute('href').value)
            @temp_result.store("name", node.css('p.productName').inner_text)
            @temp_result.store("price", node.css('p.price').inner_text.gsub(/\n|\¥|\s|円|\(|税込|\)|送料無料/,"") + "円")
            @temp_result.store("target", "Wowma!")
            # 品切れか否か
            if sale_now
              @temp_result.store("sold_out", false)
            else
              @temp_result.store("sold_out", true)
            end

            #Sort用のステータス
            @temp_result.store("for_sort_price", price_only_number)
            @result_all.push(@temp_result)
            get_count += 1
          end
        end
#      end
      @result_count.store("wowma",get_count)

    end

#    def get_info_daikokuya(result) #文字コードさえうまくいけば・・・
#      pre_url = "https://www.daikokuya78.com"
#      result.xpath('//div[@class="StyleT_Item_"]').each do |node|
#
#        sale_now = !node.css('div.img_  img_ soldout_ ').present?  #このCSSセレクタがヒットする商品は売り切れている = ヒットしない商品は販売中（sale now!）
#        price_only_number = node.css('span.price_').inner_text.gsub(/\n|\￥|\,|円/,"") #数値だけのお値段
#        # 画面上の条件指定と合致するもののみ表示対象とする
#        data_jugde(sale_now, price_only_number)
#        if @get_info_this_data
#          @temp_result = {}
#          # 各種情報の取得
#          @temp_result.store("img", pre_url + node.css('img').attribute('src').value)
#          @temp_result.store("link", pre_url + node.css('a').attribute('href').value)
#          @temp_result.store("name", node.css('span.name1_').inner_text)
#          @temp_result.store("price", node.css('span.price_').inner_text)
#          @temp_result.store("target", "大黒屋")
#          # 品切れか否か
#          if sale_now
#            @temp_result.store("sold_out", false)
#          else
#            @temp_result.store("sold_out", true)
#          end
#
#          #Sort用のステータス
#          @temp_result.store("for_sort_price", price_only_number)
#          @result_all.push(@temp_result)
#        end
#      end
#
#    end

    def data_jugde(sale_now,price_only_number)

      target_sale(sale_now)
      target_price(price_only_number)

      if @search_target_sale && @search_target_price then
        @get_info_this_data = true
      else
        @get_info_this_data = false
      end

    end

    def target_sale(sale_now)

      case params[:conditions_selected]
        when "0" #全ての商品
          @search_target_sale = true

        when "1" #販売中の商品
          if sale_now
            @search_target_sale = true
          else
            @search_target_sale = false
          end

        when "2" #売り切れの商品
          if sale_now
            @search_target_sale = false
          else
            @search_target_sale = true
          end

      end

    end

    def target_price(price_only_number)
      case params[:price_selected]

        when "0" #指定なし
          max_price = 9999999

        when "1" #1000円
          max_price = 1000

        when "2" #3000円
          max_price = 3000

        when "3" #5000円
          max_price = 5000

        when "4" #10000円
          max_price = 10000

        when "5" #30000円
          max_price = 30000

        when "6" #50000円
          max_price = 50000

        when "7" #100000円
          max_price = 100000

      end

      if price_only_number.to_i > max_price.to_i
        @search_target_price = false
      else
        @search_target_price = true
      end

    end

    def result_sort(sort_target)
      case params[:sort_selected]
        when "0" #値段の安い順
          @result_all = sort_target.sort { |a, b| b["for_sort_price"][/\d+/].to_i <=> a["for_sort_price"][/\d+/].to_i }.reverse

        when "1" #値段の高い順
          @result_all = sort_target.sort { |a, b| b["for_sort_price"][/\d+/].to_i <=> a["for_sort_price"][/\d+/].to_i }

      end
    end

end
