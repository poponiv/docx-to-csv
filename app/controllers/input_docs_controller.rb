require 'csv'

class InputDocsController < ApplicationController
  def index
    @input_docs = InputDoc.all
  end

  def new
    @input_doc = InputDoc.new
  end

  def create
    @input_doc = InputDoc.new(input_doc_params)
    if @input_doc.save
      redirect_to input_docs_path, notice: "Successfully uploaded."
      convert_to_csv @input_doc
    else
      render "new"
    end
  end

  def destroy
    @input_doc = InputDoc.find(params[:id])
    File.delete(@input_doc.attachment.current_path + '.csv')
    @input_doc.destroy
    redirect_to input_docs_path, notice:  "Successfully deleted."
  end

  def convert_to_csv(input_doc)
    doc = Docx::Document.open(input_doc.attachment.current_path)
    File.open(input_doc.attachment.current_path + '.csv' , 'w') do |csv_output_file|
      paragraphs = doc.paragraphs.filter { |p| !p.text.empty? }
      components = 0
      csv_output_file << "Article Title:,\"#{escape_quotes(paragraphs[0].text)}\",,\n,,,\n"
      csv_output_file << 'Page #,Page Titles,Page Content,Image URL'
      next_output_line = ''
      page_num = 0
      paragraphs.each do |p|
        if page_num == 0
          next_output_line += ','
          page_num = 1
          components = 2
          next
        end
        if is_title(p) && components > 0
          filler = ',' * (3 - components)
          csv_output_file << "\n#{next_output_line}#{filler}"
          next_output_line = ''
          components = 0
          page_num += 1
        end
        next_output_line += (components > 0) ? ",\"#{escape_quotes(p.text)}\"" : "#{page_num},\"#{escape_quotes(p.text)}\""
        components += 1
      end
    end
  end

  private
  def input_doc_params
    params.require(:input_doc).permit(:name, :attachment)
  end

  def is_title(p)
    p.to_html.scan(/<strong>/).length > 0
  end

  def escape_quotes(text)
    text.gsub('"','""')
  end

end
