require 'test_helper'

class PageDetailControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
