require 'open-uri'
require 'pdf-reader'
require 'RMagick'
require 'mechanize'
require 'docsplit'
require 'json'
require 'zip'
require 'Kaminari'

class DocsController < ApplicationController
  before_action :set_doc, only: [:show, :edit, :update, :destroy, :favorite, :unfavorite]
  before_action :set_attachment, only: [:document_download]
  before_filter :authenticate_user!, except: [:index]

  # GET /docs
  # GET /docs.json

  def index
    #@docs = Doc.all.order("created_at DESC").page(params[:page]).per(15)
    if params.present?
      @search = Doc.search do
        if params[:titles].present?
          keywords params[:titles], :fields => :title
          #fulltext params[:title]
        end
        if params[:documents].present?
          keywords params[:documents], :fields => :document
        end
        if params[:departments].present?
          keywords params[:departments], :fields => :source
        end
        if params[:start_time].present? and params[:end_time].present?
          with(:date_published).between(params[:start_time]..params[:end_time])
        end
        #@search = Doc.search do
        #  fulltext params[:search]
        paginate :page => params[:page], :per_page => 15
      end
      @docs = @search.results
    else
      @docs = Doc.all.order("created_at DESC").page(params[:page]).per(15)
    end
  end

  # GET /docs/1
  # GET /docs/1.json
  def show
  end


  # GET /docs/new
  def new
    @doc = current_user.docs.build
  end

  # GET /docs/1/edit
  def edit
  end

  # POST /docs
  # POST /docs.json
  def create
    tmp_params = doc_params
    html = ""
    
    uri = Addressable::URI.parse(tmp_params[:source_link]).normalize
    #urlDoc = open(uri)
    #urlDoc = Magick::Image.read(uri)
    pdf = Magick::ImageList.new(uri) {self.density = 300}
    #pdf = Magick::ImageList.new("/Users/Slava/Downloads/11.pdf") {self.density = 300}
    #pdf.from_blob(urlDoc.read) 
    pdf.each do |page_img|

      #page_img.write("/Users/Slava/Downloads/#{i}_pdf_page.jpg")
      #img = RTesseract.new(page_img)
      #img = RTesseract.new("/Users/Slava/Downloads/scan1.bmp", :lang => "rus")
      #img = RTesseract.new("/Users/Slava/Downloads/11.pdf", :lang => "rus")
      #page_img[0].format = "jpeg"
      #page_img.write("/Users/Slava/Downloads/#{i}_pdf_page.jpg")
      
      img = RTesseract.new(page_img, :lang => "rus")

      html += img.to_s
    end
    tmp_params[:document] = html
    #news_tmp_file = open('https://news.google.com')
    #parsed = Nokogiri::HTML(news_tmp_file)
    #article_css_class         =".esc-layout-article-cell"
    #article_header_css_class  ="span.titletext"
    #article_summary_css_class =".esc-lead-snippet-wrapper"
    #articles = parsed.css(article_css_class)
    #html = ""
    #prime_title = nil;
    #articles.each do |article|
    #  title_nodes = article.css(article_header_css_class)
    #  prime_title = title_nodes.first
    #  html += "%s" % prime_title.text
    #end
    #tmp_params[:document] = html

    #html = ""

    #reader = PDF::Reader.new('/Users/Slava/Downloads/2.pdf')
    #reader.pages.each do |page|
    #  html += "%s" % page.text
    #end

    #tmp_params[:document] = html


    @doc = current_user.docs.build(tmp_params)

    respond_to do |format|
      if @doc.save
        format.html { redirect_to @doc, notice: 'Doc was successfully created.' }
        format.json { render :show, status: :created, location: @doc }
      else
        format.html { render :new }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /docs/1
  # PATCH/PUT /docs/1.json
  def update
    respond_to do |format|
      if @doc.update(doc_params)
        format.html { redirect_to @doc, notice: 'Doc was successfully updated.' }
        format.json { render :show, status: :ok, location: @doc }
      else
        format.html { render :edit }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docs/1
  # DELETE /docs/1.json
  def destroy
    @doc.destroy
    respond_to do |format|
      format.html { redirect_to docs_url, notice: 'Doc was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def import_docs

    @update_list = []

    agent = Mechanize.new
    i = 1


    #-------
    temp_folder_path = 'downloads/temp/'
    
    while true do 
      main_doc_id = nil

      url = "http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?&from_4=#{i}"

      page_number = agent.get(url).links_with(:href => /from_4/).last
      
      puts page_number
      i = page_number.text.to_i
      
      
      url = "http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?&from_4=#{i}"

      if agent.get(url).links_with(:href => /id_4=/).count == 0
        break
      end
      agent.get(url) do |page|
        divs = page.search('div.proj_ttl')
        divs.reverse.each do |div| 
          puts div
          #puts div.attributes['class']
          if Doc.where("title = ?", div.at('a').text).empty?

            link = div.at('a').attributes['href'].to_s
            title = div.at('a').text.to_s

            if title.include? "О внесении изменения" or title.include? "О внесении изменений"
              #str = tmp_link.text
              str = title
              if str.include? "О внесении изменения"
                str = str.split("О внесении изменения")
              else
                str = str.split("О внесении изменений")
              end
              if str[1].include? " от "
                str = str[1]
                str = str.split(" № ")
                date = str[0]
                date = date.split(" от ")
                date = date[1]
                str = str[1]
                #str = str.split(" ")
                str = str[0].gsub(/[^\d,\.]/, '')

                @prev_doc = Doc.where('title LIKE ? and title LIKE ?', '%№ ' + str + '%', '%' + date + '%').all
                @prev_doc = @prev_doc.where.not('title LIKE ?', '%изменен%').first
              end
            end

            
            @doc = current_user.docs.create



            if title.include? " № "
              date_added = title.split(" № ")
              date_added = date_added[0]
              if date_added.include? " от "
                date_added = date_added.split(" от ")
                date_added = date_added[1]
                date_added = date_added.squish
              else
                date_added = date_added.split(" ")
                date_added = date_added.last
              end


              if date_added.include? " "
                month = date_added.split(" ")
                tmp_month = month[1]
                tmp_month = I18n.t tmp_month
                date_added = month.first + " " + tmp_month + " " + month.last
                @doc[:date_published] = date_added
              else
                @doc[:date_published] = date_added
              end
            end



            @doc[:title] = title
            @doc[:source] = "Федеральная служба по надзору в сфере образования и науки"
            if div.attributes['class'].to_s.include? "proj_zip"
              zip_path = 'downloads/' + @doc.id.to_s + '.zip'
              response = agent.get_file("http://www.obrnadzor.gov.ru/ru/docs/documents/" + link)
              #"http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?id_4=5182"
              File.open(zip_path, 'wb') {|f| f << response}
              FileUtils.mkdir_p(temp_folder_path)
              Zip::File.open(zip_path) do |zip_file|
                zip_file.each do |f|
                  fpath = File.join(temp_folder_path, f.name)
                  zip_file.extract(f, fpath) unless File.exist?(fpath)
                end
              end

              #File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
              File.delete(Rails.root.join('downloads').to_s + "/" + @doc.id.to_s + ".zip")

              list = Dir[Rails.root.join('downloads', 'temp').to_s + "/**/*.pdf"]
              extracted_text = ''
              list.each do |l|
                att_name = l.split('/').last
                FileUtils.mv(l, Rails.root.join('downloads').to_s + '/')

                @attachment = @doc.attachments.create
                File.rename(Rails.root.join('downloads').to_s + '/' + att_name, Rails.root.join('downloads').to_s + '/' + @attachment.id.to_s + '.pdf')
                @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
                @attachment[:file_content_type] = 'application/pdf'
                @attachment.save

                #extracted_text = ''
                path = 'downloads/' + @attachment.id.to_s + '.pdf'
                pdf = Magick::ImageList.new(path) {self.density = 300} 
                pdf.each do |page_img|
                  img = RTesseract.new(page_img, :lang => "rus")
                  extracted_text += img.to_s
                end
                

                Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                @list.each do |l|
                  image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')

                  @scan = @attachment.scans.create
                  @scan[:image_file_name] = image_name[1]
                  @scan[:image_content_type] = 'image/jpg'
                  @scan.save
                end

              end
              @doc[:document] = extracted_text
              FileUtils.rm_rf(Rails.root.join('downloads', 'temp').to_s + '/')
              @doc.save
            end

            if div.attributes['class'].to_s.include? "proj_doc" or div.attributes['class'].to_s.include? "proj_2" 
              @attachment = @doc.attachments.create
              path = 'downloads/' + @attachment.id.to_s + '.doc'
              response = agent.get_file("http://www.obrnadzor.gov.ru/ru/docs/documents/" + link)
              #"http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?id_4=5182"
              File.open(path, 'wb') {|f| f << response}
              @attachment[:file_file_name] = @attachment.id.to_s + '.doc'
              @attachment[:file_content_type] = 'application/doc'
              @attachment.save

              Docsplit.extract_text(path, ocr: false, output: Rails.root.join('downloads').to_s)
              extracted_text = File.read(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
              @doc[:document] = extracted_text.gsub(/\p{Cc}/, "")
              
              File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")



              Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
              @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
              @list.each do |l|
                image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                @scan = @attachment.scans.create
                @scan[:image_file_name] = image_name[1]
                @scan[:image_content_type] = 'image/jpg'
                @scan.save
              end
              @doc.save
            end

            if div.attributes['class'].to_s.include? "proj_xls" or div.attributes['class'].to_s.include? "proj_3" 
              @attachment = @doc.attachments.create
              path = 'downloads/' + @attachment.id.to_s + '.xls'
              response = agent.get_file("http://www.obrnadzor.gov.ru/ru/docs/documents/" + link)
              #"http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?id_4=5182"
              File.open(path, 'wb') {|f| f << response}
              @attachment[:file_file_name] = @attachment.id.to_s + '.xls'
              @attachment[:file_content_type] = 'application/xls'
              @attachment.save

              Docsplit.extract_text(path, ocr: false, output: Rails.root.join('downloads').to_s)
              extracted_text = File.read(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
              @doc[:document] = extracted_text.gsub(/\p{Cc}/, "")
              
              File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")



              Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
              @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
              @list.each do |l|
                image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                @scan = @attachment.scans.create
                @scan[:image_file_name] = image_name[1]
                @scan[:image_content_type] = 'image/jpg'
                @scan.save
              end
              @doc.save
            end

            if div.attributes['class'].to_s.include? "proj_pdf"
              @attachment = @doc.attachments.create
              path = 'downloads/' + @attachment.id.to_s + '.pdf'
              response = agent.get_file("http://www.obrnadzor.gov.ru/ru/docs/documents/" + link)
              #"http://www.obrnadzor.gov.ru/ru/docs/documents/index.php?id_4=5182"
              File.open(path, 'wb') {|f| f << response}
              @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
              @attachment[:file_content_type] = 'application/pdf'
              @attachment.save

              extracted_text = ''
              path = 'downloads/' + @attachment.id.to_s + '.pdf'
              pdf = Magick::ImageList.new(path) {self.density = 300} 
              pdf.each do |page_img|
                img = RTesseract.new(page_img, :lang => "rus")
                extracted_text += img.to_s
              end
              @doc[:document] = extracted_text

              Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
              @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
              @list.each do |l|
                image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                
                @scan = @attachment.scans.create
                @scan[:image_file_name] = image_name[1]
                @scan[:image_content_type] = 'image/jpg'
                @scan.save
              end              
              @doc.save
            end
            


            if div.attributes['class'].to_s.include? " proj_ "
              @original = Doc.find(main_doc_id)
              @original.updates << @doc
              @original = nil
            else
              main_doc_id = @doc.id
            end
            #puts div.at('a').text
            if !@prev_doc.nil?
              @prev_doc.updates << @doc
              @update_list << @prev_doc
            end
            @prev_doc = nil


          end
          #break
        end
      end



      break
      i -= 1

    end

    i = 1

    while true do

      url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
      if agent.get(url).links_with(:class => 'media-item-link').count == 0
        i -= 1
        break
      end
      i += 1

    end
    i = 2
    while i > 0 do
      url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
      agent.get(url) do |page|
        page.links_with(:class => 'media-item-link').reverse.each do |link|
          #puts link.text
          tmp_page = agent.click(link)

          tmp_links = tmp_page.links_with(:href => %r{pdf})

          if Doc.where("title = ?", link.text).empty?
            #if tmp_link.text.include? "О внесении изменения" or tmp_link.text.include? "О внесении изменений"
            if link.text.include? "О внесении изменения" or link.text.include? "О внесении изменений"
              #str = tmp_link.text
              str = link.text
              if str.include? "О внесении изменения"
                str = str.split("О внесении изменения")
              else
                str = str.split("О внесении изменений")
              end
              if str[1].include? " от "
                str = str[1]
                str = str.split(". № ")
                date = str[0]
                date = date.split(" от ")
                date = date[1]
                str = str[1]
                str = str.split(" ")
                str = str[0].gsub(/[^\d,\.]/, '')

                @original = Doc.where('title LIKE ? and title LIKE ?', '%№ ' + str + '%', '%' + date + '%').all
                @original = @original.where.not('title LIKE ?', '%изменен%').first
              end
            end
            @doc = current_user.docs.build
            #@doc[:title] = tmp_link.text
            if link.text.include? " № "
              date_added = link.text
              date_added = date_added.split("г. № ")
              date_added = date_added[0].squish
              date_added = date_added.split(" от ")
              date_added = date_added[1]
              month = date_added.split(" ")
              tmp_month = month[1]
              tmp_month = I18n.t tmp_month
              date_added = month.first + " " + tmp_month + " " + month.last
              @doc[:date_published] = date_added              
            end

            @doc[:title] = link.text
            html = ''
            #-------------------------
            tmp_links.each do |tmp_link|
              pdf = Magick::ImageList.new(tmp_link.href) {self.density = 300} 
              pdf.each do |page_img|
                img = RTesseract.new(page_img, :lang => "rus")
                html += img.to_s
              end
            end
            @doc[:document] = html
            @doc[:source] = "Министерство образования и науки Российской Федерации"
            @doc.save
            #-----------------------




            #---------------------------
            if !@original.nil?
              @original.updates << @doc
              @update_list << @original
            end
            @original = nil
            #------------------
            tmp_links.each do |tmp_link|
              @attachment = @doc.attachments.create
              path = 'downloads/' + @attachment.id.to_s + '.pdf'
              open(path, 'wb') do |file|
                file << open(tmp_link.href).read
                
                @attachment[:title] = tmp_link.text
                #@attachment[:file_file_name] = file
                @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
                @attachment[:file_content_type] = 'application/pdf'
                @attachment.save

              end

              Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
              @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
              @list.each do |l|
                image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                #puts x[1]
                @scan = @attachment.scans.create
                @scan[:image_file_name] = image_name[1]
                @scan[:image_content_type] = 'image/jpg'
                @scan.save
              end

            end



        #    break 
      end

    end
        #break 
      end
      i -= 1
      #break 
    end
    #if i == 1
    #  break
    #end
      #break 
      #i -= 1
    #end


    #----------------------------------------------END

    url = 'https://regulation.gov.ru/Npa/CollectionRead?mnemonic=Npa_AreaRegulation_Grid'
    f = open(url).read
    result = JSON.parse(f)


    results = result['Data'].select {|h1| h1["CreatorDepartment"]["Title"] == "Минобрнауки России"}

    i = 0
    results.each do |record|

      id = record['ID']
      url = "http://regulation.gov.ru/Npa/GetAjaxForm?id=#{id}&mnemonic=Npa_AreaRegulation_ListView&readonly=true&_dialogid=dialog_3d21f08364fa404db62e4375f3a432a1&_widgetid=widget_ffed2bcef4094d918ecb9978d2c03d99&_dialogtype=Modal&_parentid=&_currentid="
      agent.get(url) do |page|
        tmp_links = page.links_with(:class => 'file-link')

        if !tmp_links.empty?
          if Doc.where("title = ?", record['Title']).empty?
            if record['Title'].include? "О внесении изменения" or record['Title'].include? "О внесении изменений"
              #str = tmp_link.text
              str = record['Title']

              if str.include? "О внесении изменения"
                str = str.split("О внесении изменения")
              else
                str = str.split("О внесении изменений")
              end
              if str[1].include? " от "
                str = str[1]
                str = str.squish
                str = str.split(". № ")

                
                date = str[0]
                date = date.split(" от ")
                
                date = date[1]
                puts date
                str = str[1]
                str = str.split(" ")
                
                str = str[0].gsub(/[^\d,\.]/, '')


                @original = Doc.where('title LIKE ? and title LIKE ?', '%№ ' + str + '%', '%' + date + '%').all
                @original = @original.where.not('title LIKE ?', '%изменен%').first
              else
                str = str[1]

                str = str.split(" в ")

                @original = Doc.where('title LIKE ?', '%' + str[1] + '%').all
                @original = @original.where.not('title like ?', '%изменен%').first
              end
            else
              str = record['Title']
              if str.include? " от "
                str = str[1]

                str = str.split(". № ")

                date = str[0]

                date = date.split(" от ")

                date = date[1]

                str = str[1]

                str = str.split(" ")

                str = str[0].gsub(/[^\d,\.]/, '')


                @changes = Doc.where('title LIKE ? and title LIKE ? and title LIKE ?', '%№ ' + str + '%', '%' + date + '%', '%изменен%').first
              else
                @changes = Doc.where('title LIKE ? and title LIKE ?', '%' + str + '%', '%изменен%').all
              end
            end




            extracted_text = ''
            @doc = current_user.docs.create
            @doc[:title] = record['Title']
            @doc[:project] = true
            date_added = record['PublishDate'].to_s
            date_added = date_added.split(" ")
            date_added = date_added[0]
            @doc[:date_published] = date_added
            tmp_links.each do |link|
          #puts tmp_links.first.attributes['title']

          if link.attributes['title'].include? ".doc" or link.attributes['title'].include? ".docx"

            if !link.href.nil?

                  #contains принятый project = false
                  @attachment = @doc.attachments.create
                  tmp_title = link.attributes['title'].split('Скачать:')
                  @attachment[:title] = tmp_title[1]
                  if tmp_title[1].include? "Итоговый"
                    @doc[:project] = false
                  end


                  path = 'downloads/' + @attachment.id.to_s + '.doc'
                  response = agent.get_file("http://regulation.gov.ru/" + link.href)
                  File.open(path, 'wb') {|f| f << response}
                  @attachment[:file_file_name] = @attachment.id.to_s + '.doc'
                  @attachment[:file_content_type] = 'application/doc'
                  @attachment.save

                  Docsplit.extract_text(path, ocr: false, output: Rails.root.join('downloads').to_s)
                  extracted_text += File.read(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
                  extracted_text = extracted_text.gsub(/\p{Cc}/, "")

                  File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
                  


                  Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                  @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                  @list.each do |l|
                    image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                    @scan = @attachment.scans.create
                    @scan[:image_file_name] = image_name[1]
                    @scan[:image_content_type] = 'image/jpg'
                    @scan.save
                  end
                end
              end

              if link.attributes['title'].include? ".pdf"
                if !link.href.nil?

                  @attachment = @doc.attachments.create
                  tmp_title = link.attributes['title'].split('Скачать:')
                  @attachment[:title] = tmp_title[1]
                  if tmp_title[1].include? "Итоговый"
                    @doc[:project] = false
                  end

                  path = 'downloads/' + @attachment.id.to_s + '.pdf'
                  response = agent.get_file("http://regulation.gov.ru/" + link.href)
                  File.open(path, 'wb') {|f| f << response}
                  @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
                  @attachment[:file_content_type] = 'application/pdf'
                  @attachment.save


                  #extracted_text = ''
                  pdf = Magick::ImageList.new(path) {self.density = 300} 
                  pdf.each do |page_img|
                    img = RTesseract.new(page_img, :lang => "rus")
                    extracted_text += img.to_s
                  end
                  

                  Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                  @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                  @list.each do |l|
                    image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')

                    @scan = @attachment.scans.create
                    @scan[:image_file_name] = image_name[1]
                    @scan[:image_content_type] = 'image/jpg'
                    @scan.save
                  end
                end
              end

              @doc[:source] = "Федеральный портал проектов нормативных правовых актов"
              @doc[:document] = extracted_text
              @doc.save
              if !@original.nil?
                @original.updates << @doc
                @update_list << @original
              end
              @original = nil
              if !@changes.empty?
                @changes.each do |change|
                  @doc.updates << change
                end
                @update_list << @doc
              end
              @changes = []
              #end
            end
          else

            if Doc.where("title = ?", record['Title']).first.project? and !Doc.where("title = ?", record['Title']).first.attachments.empty?
              @proj = Doc.where("title = ?", record['Title']).first
              if tmp_links.count != @proj.attachments.count
                tmp_links.each do |link|
                  tmp_title = link.attributes['title'].split('Скачать:')
                  if @proj.attachments.where("title = ?", tmp_title[1]).empty?
                    extracted_text = @proj.document
                    if link.attributes['title'].include? ".doc" or link.attributes['title'].include? ".docx"

                      if !link.href.nil?

                      #contains принятый project = false
                      @attachment = @proj.attachments.create
                      tmp_title = link.attributes['title'].split('Скачать:')
                      @attachment[:title] = tmp_title[1]
                      if tmp_title[1].include? "Итоговый"
                        @proj[:project] = false
                      end


                      path = 'downloads/' + @attachment.id.to_s + '.doc'
                      response = agent.get_file("http://regulation.gov.ru/" + link.href)
                      File.open(path, 'wb') {|f| f << response}
                      @attachment[:file_file_name] = @attachment.id.to_s + '.doc'
                      @attachment[:file_content_type] = 'application/doc'
                      @attachment.save

                      Docsplit.extract_text(path, ocr: false, output: Rails.root.join('downloads').to_s)
                      extracted_text += File.read(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
                        #extracted_text += @proj.document
                        extracted_text = extracted_text.gsub(/\p{Cc}/, "")

                        File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")



                        Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                        @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                        @list.each do |l|
                          image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                          @scan = @attachment.scans.create
                          @scan[:image_file_name] = image_name[1]
                          @scan[:image_content_type] = 'image/jpg'
                          @scan.save
                        end
                      end
                    end
                    if link.attributes['title'].include? ".pdf"
                      if !link.href.nil?

                        @attachment = @proj.attachments.create
                        tmp_title = link.attributes['title'].split('Скачать:')
                        @attachment[:title] = tmp_title[1]
                        if tmp_title[1].include? "Итоговый"
                          @proj[:project] = false
                        end

                        path = 'downloads/' + @attachment.id.to_s + '.pdf'
                        response = agent.get_file("http://regulation.gov.ru/" + link.href)
                        File.open(path, 'wb') {|f| f << response}
                        @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
                        @attachment[:file_content_type] = 'application/pdf'
                        @attachment.save


                        extracted_text = ''
                        pdf = Magick::ImageList.new(path) {self.density = 300} 
                        pdf.each do |page_img|
                          img = RTesseract.new(page_img, :lang => "rus")
                          extracted_text += img.to_s
                        end
                        #@doc[:document] = extracted_text


                        Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                        @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                        @list.each do |l|
                          image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')

                          @scan = @attachment.scans.create
                          @scan[:image_file_name] = image_name[1]
                          @scan[:image_content_type] = 'image/jpg'
                          @scan.save
                        end
                      end
                    end
                    @proj[:document] = extracted_text

                    @proj.save
                    @update_list << @proj
                    #@proj = nil
                  end
                end
              end
            else
              @proj = Doc.where("title = ?", record['Title']).first
              extracted_text = ''
              tmp_links.each do |link|
                tmp_title = link.attributes['title'].split('Скачать:')
                if link.attributes['title'].include? ".doc" or link.attributes['title'].include? ".docx"
                  if !link.href.nil?
                    @attachment = @proj.attachments.create
                    tmp_title = link.attributes['title'].split('Скачать:')
                    @attachment[:title] = tmp_title[1]
                    if tmp_title[1].include? "Итоговый"
                      @proj[:project] = false
                    end


                    path = 'downloads/' + @attachment.id.to_s + '.doc'
                    response = agent.get_file("http://regulation.gov.ru/" + link.href)
                    File.open(path, 'wb') {|f| f << response}
                    @attachment[:file_file_name] = @attachment.id.to_s + '.doc'
                    @attachment[:file_content_type] = 'application/doc'
                    @attachment.save

                    Docsplit.extract_text(path, ocr: false, output: Rails.root.join('downloads').to_s)
                    extracted_text += File.read(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
                    #extracted_text += @proj.document
                    extracted_text = extracted_text.gsub(/\p{Cc}/, "")

                    File.delete(Rails.root.join('downloads').to_s + "/" + @attachment.id.to_s + ".txt")
                    Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                    @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                    @list.each do |l|
                      image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')
                      @scan = @attachment.scans.create
                      @scan[:image_file_name] = image_name[1]
                      @scan[:image_content_type] = 'image/jpg'
                      @scan.save
                    end
                  end
                end
                if link.attributes['title'].include? ".pdf"
                  if !link.href.nil?

                    @attachment = @proj.attachments.create
                    tmp_title = link.attributes['title'].split('Скачать:')
                    @attachment[:title] = tmp_title[1]
                    if tmp_title[1].include? "Итоговый"
                      @proj[:project] = false
                    end

                    path = 'downloads/' + @attachment.id.to_s + '.pdf'
                    response = agent.get_file("http://regulation.gov.ru/" + link.href)
                    File.open(path, 'wb') {|f| f << response}
                    @attachment[:file_file_name] = @attachment.id.to_s + '.pdf'
                    @attachment[:file_content_type] = 'application/pdf'
                    @attachment.save


                    extracted_text = ''
                    pdf = Magick::ImageList.new(path) {self.density = 300} 
                    pdf.each do |page_img|
                      img = RTesseract.new(page_img, :lang => "rus")
                      extracted_text += img.to_s
                    end
                    #@doc[:document] = extracted_text


                    Docsplit.extract_images(path, :size => '500x', :format => [:jpg], :output => Rails.root.join('app', 'assets', 'images').to_s)
                    @list = Dir[Rails.root.join('app', 'assets', 'images').to_s + "/#{@attachment.id}_*"]
                    @list.each do |l|
                      image_name = l.split(Rails.root.join('app', 'assets', 'images').to_s + '/')

                      @scan = @attachment.scans.create
                      @scan[:image_file_name] = image_name[1]
                      @scan[:image_content_type] = 'image/jpg'
                      @scan.save
                    end
                  end
                end
                @proj[:document] = extracted_text
                @proj.save
                if !@proj.attachments.empty?
                  @update_list << @proj
                end
              end
            end

          end
        end
      end
      i += 1
      if i == 20
        break
      end
    end


    if !@update_list.empty?
      User.where("subscription = 3").each do |user|
        Usermailer.send_updates(current_user, @update_list).deliver_now
      end
    end
    @update_list = []

    redirect_to docs_url
  end

  def document_download
    send_file @attachment.file.path, :type => @attachment.file_content_type, :x_sendfile=>true
  end

  def favorite
    @doc.liked_by current_user
    
    respond_to do |format|
      format.html { redirect_to @doc}
      format.js
    end
    #redirect_to @doc
  end

  def unfavorite
    @doc.unliked_by current_user
    
    respond_to do |format|
      format.html { redirect_to @doc}
      format.js 
    end
    #redirect_to @doc
  end

  def favorites
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doc
      @doc = Doc.find(params[:id])
    end

    def set_attachment
      @attachment = Attachment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def doc_params
      params.require(:doc).permit(:title)
    end
  end






  
