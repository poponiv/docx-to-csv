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
    else
      render "new"
    end
  end

  def destroy
    @input_doc = InputDoc.find(params[:id])
    @input_doc.destroy
    redirect_to input_docs_path, notice:  "Successfully deleted."
  end

  private
  def input_doc_params
    params.require(:input_doc).permit(:name, :attachment)
  end

end
