require 'open-uri'
require 'pdf-reader'
require 'RMagick'

class DocsController < ApplicationController
  before_action :set_doc, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, except: [:index]

  # GET /docs
  # GET /docs.json
  def index
    @docs = Doc.all.order("created_at DESC")
    if params[:search]
      @docs = Doc.search(params[:search]).order("created_at DESC")
    else
      @docs = Doc.all.order("created_at DESC")
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doc
      @doc = Doc.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def doc_params
      params.require(:doc).permit(:title, :source, :source_link, :document, :url)
    end
end
