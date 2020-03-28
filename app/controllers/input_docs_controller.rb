require 'csv'

class InputDocsController < ApplicationController
  def index
    @input_docs = InputDoc.all.select { |idoc| puts idoc.attachment.current_path; File.exist?(idoc.attachment.current_path + '.csv')}
  end

  def new
    @input_doc = InputDoc.new
  end

  def show
    @input_doc = InputDoc.find(params[:id])
  end

  def create
    begin
      @input_doc = InputDoc.new(input_doc_params)
      @input_doc.name = File.basename(@input_doc.attachment_url) if @input_doc.attachment_url.present?
      @input_doc.save!
      convert_to_csv @input_doc
      notice = "Successfully uploaded."
    rescue Exception => e
      notice = "Upload Failed: #{e.message}"
    end
    redirect_to input_docs_path, notice: notice
  end

  def destroy
    @input_doc = InputDoc.find(params[:id])
    File.delete(@input_doc.attachment.current_path + '.csv')
    @input_doc.destroy
    redirect_to input_docs_path, notice:  "Successfully deleted."
  end

  private
  def convert_to_csv(input_doc)
    doc = Docx::Document.open(input_doc.attachment.current_path)
    File.open(input_doc.attachment.current_path + '.csv' , 'w') do |csv_output_file|
      paragraphs = doc.paragraphs.filter { |p| !p.text.match(/^\s*$/) }
      csv_output_file << "Article Title:,\"#{escape_quotes(paragraphs[0].text)}\",,\n,,,\n"
      csv_output_file << 'Page #,Page Titles,Page Content,Image URL'
      next_output_line = ','
      page_num = 0
      components = 2
      paragraphs[1 .. -1].each_with_index do |p, ind|
        p_num = ind+1 # Shift by 1 because we skipped the first paragraph
        if is_title(p)
          filler = ',' * ([3 - components, 0].max)
          csv_output_file << "\n#{next_output_line}#{filler}"
          next_output_line = ''
          components = 0
          page_num += 1
        end
        if components > 0
          if paragraphs[p_num+1].present? && !is_title(paragraphs[p_num+1]) && !is_title(paragraphs[p_num-1])
            next_output_line.chop!
            next_output_line += "\n#{escape_quotes(p.text)}\""
          else
            next_output_line += ",\"#{escape_quotes(p.text)}\""
          end
        else
          next_output_line += "#{page_num},\"#{escape_quotes(p.text)}\""
        end
        components += 1
      end
      filler = ',' * ([3 - components, 0].max)
      csv_output_file << "\n#{next_output_line}#{filler}"
    end
  end

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
