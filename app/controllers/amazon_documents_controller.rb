class AmazonDocumentsController < ApplicationController
  def index
    @amazon_documents = AmazonDocument.all.select { |idoc| puts idoc.attachment.current_path; File.exist?(idoc.attachment.current_path + '.csv')}
  end

  def new
    @amazon_document = AmazonDocument.new
  end

  def show
    @amazon_document = AmazonDocument.find(params[:id])
  end

  def create
    begin
      @amazon_document = AmazonDocument.new(amazon_document_params)
      @amazon_document.name = File.basename(@amazon_document.attachment_url) if @amazon_document.attachment_url.present?
      @amazon_document.save!
      convert_to_csv @amazon_document
      notice = "Successfully uploaded."
    rescue Exception => e
      notice = "Upload Failed: #{e.message}"
    end
    redirect_to amazon_documents_path, notice: notice
  end

  def destroy
    @amazon_document = AmazonDocument.find(params[:id])
    File.delete(@amazon_document.attachment.current_path + '.csv')
    @amazon_document.destroy
    redirect_to amazon_documents_path, notice: "Successfully deleted."
  end

  private
  def convert_to_csv(amazon_doc)
    doc = Docx::Document.open(amazon_doc.attachment.current_path)
    File.open(amazon_doc.attachment.current_path + '.csv' , 'w') do |csv_output_file|
      paragraphs = doc.paragraphs.filter { |p| !p.text.match(/^\s*$/) }
      content_start = convert_intro(csv_output_file, paragraphs)
      next_output_line = ''
      components = 0
      page_num = 0
      paragraphs[content_start .. -1].each_with_index do |p, ind|
        p_num = ind+content_start
        if is_title(p)
          filler = ',' * ([6 - components, 0].max)
          csv_output_file << "\n#{next_output_line}#{filler}" if !next_output_line.empty?
          next_output_line = ''
          page_num += 1
          next_output_line += "#{page_num},\"#{escape_quotes(p.text)}\""
          components = 0
        # elsif paragraphs[p_num+1].present? && components == 1 && !is_image(paragraphs[p_num+1])
        #   next_output_line.chop!
        #   next_output_line += "\n#{escape_quotes(p.text)}\""
        else
          next_output_line += ",\"#{escape_quotes(p.text)}\""
        end
        components += 1
      end
      filler = ',' * ([6 - components, 0].max)
      csv_output_file << "\n#{next_output_line}#{filler}"
    end
  end

  def convert_intro(csv_output_file, paragraphs)
    csv_output_file << "Article Title:,\"#{escape_quotes(paragraphs[0].text)}\",,,,,\n,,,,,,\n"
    csv_output_file << 'Page #,Page Titles,Page Content,Image URL,Price,AFFA Link, HL Keyword'
    next_output_line = "\n,,\"#{escape_quotes(paragraphs[1].text)}\""
    next_p = 2
    while !is_title(paragraphs[next_p])
      next_output_line.chop!
      next_output_line += "\n#{escape_quotes(paragraphs[next_p])}\""
      next_p += 1
    end
    next_output_line += ",,,,"
    csv_output_file << next_output_line
    next_p
  end

  def amazon_document_params
    params.require(:amazon_document).permit(:name, :attachment)
  end

  def is_title(p)
    p.to_html.scan(/<strong>/).length > 0
  end

  def is_image(p)
    require 'byebug'; byebug
    p.text.start_with? 'https://i.imgur.com'
  end

  def escape_quotes(text)
    text.gsub('"','""')
  end
end
