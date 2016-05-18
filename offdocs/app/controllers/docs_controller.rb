require 'open-uri'
require 'pdf-reader'
require 'RMagick'
require 'mechanize'

class DocsController < ApplicationController
  before_action :set_doc, only: [:show, :edit, :update, :destroy, :document_download]
  before_filter :authenticate_user!, except: [:index]

  # GET /docs
  # GET /docs.json
  def index
    @docs = Doc.all.order("created_at DESC")
    if params[:search]
    #  @docs = Doc.search(params[:search]).order("created_at DESC")
    @search = Doc.search do
     fulltext params[:search]
   end
   @docs = @search.results
 else
  @docs = Doc.all.order("created_at DESC")
end

end

  # GET /docs/1
  # GET /docs/1.json
  def show
    if !@doc.updates.empty?
      flash.now[:notice] = "Something has changed"
    end
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
    #@doc = current_user.docs.build
    #@doc.save
    agent = Mechanize.new
    i = 1
    #url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
    
    while true do
      #url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
    #url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B?keywords=228"
      puts i
      url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
      if agent.get(url).links_with(:class => 'media-item-link').count == 0
        i -= 1
        break
      end
      i += 1

    end
    i = 2
    #page = agent.get(url)
    puts i
    while i > 0 do
      url = "http://xn--80abucjiibhv9a.xn--p1ai/%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D1%8B/by-page?page=#{i}&keywords=228"
      agent.get(url) do |page|
        page.links_with(:class => 'media-item-link').each do |link|
          #puts link.text
          tmp_page = agent.click(link)
          #pp pagex
          #pagex.links_with(:href => %r{pdf}).each do |link|
          #  puts link.href
          #end
          tmp_link = tmp_page.links_with(:href => %r{pdf}).first
          #puts "___________________"
          #puts link.text
          #if tmp_link.nil?
          #  tmp_link.text = link.text
          #end
          #if Doc.where("title = ?", tmp_link.text).empty?
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
                str = str.split("№ ")
                str = str[1]
                str = str.split(" ")
                str = str[0].gsub(/[^\d,\.]/, '')
                #@search = Doc.search do
                  
                #  fulltext str
                  
                #end
                @original = Doc.where('title LIKE ?', '%№ ' + str + '%').all
                @original = @original.where.not('title LIKE ?', '%изменен%').first
              end
            end
            @doc = current_user.docs.build
            #@doc[:title] = tmp_link.text
            @doc[:title] = link.text
            #-------------------------
            #pdf = Magick::ImageList.new(tmp_link.href) {self.density = 300} 
            #html = ''
            #pdf.each do |page_img|
            #  img = RTesseract.new(page_img, :lang => "rus")
            #  html += img.to_s
            #end

            #@doc[:document] = html
            @doc.save
            #-----------------------




          
          
            #---------------------------
            if !@original.nil?
              @original.updates << @doc
            end
            @original = nil
            #------------------
            #path = 'downloads/' + @doc.id.to_s + '.pdf'
            #open(path, 'wb') do |file|
            #  file << open(tmp_link.href).read
            #  @doc[:attachment_file_name] = file
            #  @doc[:attachment_content_type] = 'application/pdf'
            #end
          

            #@doc[:attachment_file_name] = 'downloads/' + @doc.id.to_s + '.pdf'
            #@doc.save
            #----------------------

            #break #BREAK HERE TEST
          end
        end
      end
      i -= 1
    end
    #if i == 1
    #  break
    #end
      #break #HERE TOO
      #i -= 1
    #end
    
    #puts page.links_with(:class => 'media-item-link').count
    #page.links_with(:id => 'more_docs').first.click
    #puts page.links_with(:class => 'media-item-link').count
    redirect_to docs_url
  end

  def document_download
    send_file @doc.attachment.path, :type => @doc.attachment_content_type, :x_sendfile=>true
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doc
      @doc = Doc.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def doc_params
      params.require(:doc).permit(:title, :source, :source_link, :document, :url, :attachment_file_name, :original_id)
    end
  end
