require 'test_helper'

class InputDocsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get input_docs_index_url
    assert_response :success
  end

  test "should get new" do
    get input_docs_new_url
    assert_response :success
  end

  test "should get create" do
    get input_docs_create_url
    assert_response :success
  end

  test "should get destroy" do
    get input_docs_destroy_url
    assert_response :success
  end

end
