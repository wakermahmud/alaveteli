require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CensorRule, "substituting things" do

    describe 'when using a text rule' do

        before do
            @censor_rule = CensorRule.new
            @censor_rule.text = "goodbye"
            @censor_rule.replacement = "hello"
        end

        it 'should do basic text substitution' do
            body = "I don't know why you say goodbye"
            @censor_rule.apply_to_text!(body)
            body.should == "I don't know why you say hello"
        end

        it 'should keep size same for binary substitution' do
            body = "I don't know why you say goodbye"
            orig_body = body.dup
            @censor_rule.apply_to_binary!(body)
            body.size.should == orig_body.size
            body.should == "I don't know why you say xxxxxxx"
            body.should_not == orig_body # be sure duplicated as expected
        end

    end

    describe "when using a regular expression rule" do

        before do
            @censor_rule = CensorRule.new(:last_edit_editor => 1,
                                          :last_edit_comment => 'comment')
            @censor_rule.text = "--PRIVATE.*--PRIVATE"
            @censor_rule.replacement = "--REMOVED\nHidden private info\n--REMOVED"
            @censor_rule.regexp = true
        end

        it "replaces with the regexp" do
            body =
<<BODY
Some public information
--PRIVATE
Some private information
--PRIVATE
BODY
            @censor_rule.apply_to_text!(body)
            body.should ==
<<BODY
Some public information
--REMOVED
Hidden private info
--REMOVED
BODY
        end

    end

end

describe 'when validating rules' do

    describe 'when the allow_global flag has been set' do

        before do
            @censor_rule = CensorRule.new
            @censor_rule.allow_global = true
        end

        it 'should allow a global censor rule (without user_id, request_id or public_body_id)' do
            @censor_rule.valid?.should == true
        end

    end

    describe 'when the allow_global flag has not been set' do

        before do
            @censor_rule = CensorRule.new()
        end

        it 'should not allow a global censor rule (without user_id, request_id or public_body_id)' do
            @censor_rule.valid?.should == false
            @expected_error = 'Censor must apply to an info request a user or a body;  is invalid'
            @censor_rule.errors.full_messages.should == [@expected_error]
        end

    end

end

describe 'when handling global rules' do

    describe 'an instance without user_id, request_id or public_body_id' do

        before do
            @global_rule = CensorRule.new
        end

        it 'should return a value of true from is_global?' do
           @global_rule.is_global?.should == true
        end

    end

    describe 'the scope CensorRule.global.all' do

        before do
            @global_rule = CensorRule.create!(:allow_global => true,
                                              :text => 'hide me',
                                              :replacement => 'nothing to see here',
                                              :last_edit_editor => 1,
                                              :last_edit_comment => 'comment')
            @user_rule = CensorRule.create!(:user_id => 1,
                                            :text => 'hide me',
                                            :replacement => 'nothing to see here',
                                            :last_edit_editor => 1,
                                            :last_edit_comment => 'comment')
        end

        it 'should include an instance without user_id, request_id or public_body_id' do
            CensorRule.global.all.include?(@global_rule).should == true
        end

        it 'should not include a request with user_id' do
            CensorRule.global.all.include?(@user_rule).should == false
        end

        after do
            @global_rule.destroy if @global_rule
            @user_rule.destroy if @user_rule
        end
    end

end


