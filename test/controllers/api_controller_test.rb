require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "should get stop" do
    get :stop
    assert_response :success
  end

end
