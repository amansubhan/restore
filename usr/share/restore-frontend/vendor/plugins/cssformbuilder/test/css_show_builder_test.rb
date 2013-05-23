require 'test/test_helper'

#require File.dirname(__FILE__) +'/../init.rb'
require File.dirname(__FILE__) +"/../lib/css_form_support.rb"
require File.dirname(__FILE__) +"/../lib/css_form_builder.rb"
require File.dirname(__FILE__) +"/../lib/css_show_builder.rb"

def _(s); "__#{s}__" end

class CssShowBuilderTest < Test::Unit::TestCase

  include Test::Unit::Assertions
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::PrototypeHelper
  
  #just copied from original FormHelperTest
  
  silence_warnings do
    Post = Struct.new("Post", :title, :author_name, :body, :secret, :written_on, :cost)
    Post.class_eval do
      alias_method :title_before_type_cast, :title unless respond_to?(:title_before_type_cast)
      alias_method :body_before_type_cast, :body unless respond_to?(:body_before_type_cast)
      alias_method :author_name_before_type_cast, :author_name unless respond_to?(:author_name_before_type_cast)
    end
  end
  
  def setup
    @post = Post.new
    def @post.errors() Class.new{ def on(field) field == "author_name" end }.new end

    def @post.id; 123; end
    def @post.id_before_type_cast; 123; end

    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret      = 1
    @post.written_on  = Date.new(2004, 6, 15)

    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options, *parameters_for_method_reference)
        @url_for_options = options
        "http://www.example.com"
      end
    end
    @controller = @controller.new
    CssBuilder.no_translate
  end

  def test_css_show_for
    expected=content_tag('div',expected_output('Title','&nbsp;Hello World'), :class=>'css_show')
 
    _erbout = ''
    css_show_for(:post, @post,:html=>{:id=>'form1'}) do |f|
      _erbout.concat f.text_field(:title)
    end
    assert_dom_equal expected, _erbout
  end
  
  def test_remote_css_form_for
    expected=content_tag('div',expected_output('Title','&nbsp;Hello World'), :class=>'css_show')
    #note: id attribute not expected
 
    _erbout = ''
    remote_css_show_for(:post, @post,:html=>{:id=>'form1'}) do |f|
      _erbout.concat f.text_field(:title)
    end
    assert_dom_equal expected, _erbout
  end
  
  def test_text_field_with_label
    _erbout = ''
    expected=expected_output('Custom label','&nbsp;Hello World')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title, :label=>'Custom label')
    end
  end
  
  def test_text_field_without_label
    _erbout = ''
    expected=expected_output(false, '&nbsp;Hello World')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title, :label=>false)
    end
  end
  
  def test_text_area_without_label
    _erbout = ''
    expected=expected_output(false, '<pre>Hello World</pre>', :class=>'textarea')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_area(:title, :label=>false)
    end
  end
  
  def test_text_field_with_extra_tag
    _erbout = ''
    expected=expected_output('Custom label','&nbsp;Hello World')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title, {:label=>'Custom label', :extra=>'XYZ'})
    end
  end
  
  def test_text_field_with_error_and_class
    _erbout = ''
    expected=expected_output('Author name','&nbsp;',:class=>'double-size')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:author_name,:class=>'double-size')
    end
  end
  
  def test_field_with_translated_label
    CssBuilder.translate_as_gettext
    _erbout = ''
    expected=expected_output('__Title__','&nbsp;Hello World')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.text_field(:title)
    end
  end
  
  def test_hidden_field
    _erbout = ''
    css_show_for(:post, @post) do |f|
      assert_nil f.hidden_field(:title)
    end
  end
    
  def test_select
    _erbout = ''
    hash=[['one',1],['two',2]]
    expected=expected_output('Secret','&nbsp;one')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.select(:secret, hash)
    end
  end
  
  def test_select_with_choises
    _erbout = ''
    hash=[['one',1],['two',2]]
    expected=expected_output('Secret','&nbsp;one')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.select_with_choises(:secret,  options_for_select(hash,1))
    end
  end
  
  def test_check_box
    _erbout = ''
    #expected="<label>Secret:<span class='checkbox'>&nbsp;1</span></label>"
    expected=expected_output('Secret','&nbsp;1',:class=>'checkbox')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.check_box(:secret)
    end
  end
    
  def test_radio_button
    _erbout = ''
    #expected="<label>Secret:<span class='radiobutton'>&nbsp;X</span></label>"
    expected=expected_output('Secret','&nbsp;X',:class=>'radiobutton')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.radio_button(:secret,1)
    end
  end
  
  def test_date_select
    _erbout = ''
    expected=expected_output('Written on','&nbsp;'+ @post.written_on.to_s)
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.date_select(:written_on)
    end
  end
  
  def test_password_field
    _erbout = ''
    expected=expected_output('Secret','&nbsp;******')
    css_show_for(:post, @post) do |f|
      assert_dom_equal expected, f.password_field(:secret)
    end
  end
  
  def test_fields_for
    _erbout = ''
    expected= expected_output('Title','&nbsp;Hello World')
    css_show_for(:post, @post) do |f|
      f.fields_for :post, @post do |f1| 
        assert_dom_equal expected, f1.text_field(:title)
      end
    end
  end
  
  private
  
  def expected_output(label,output,tags=nil)
    s="    <div class='form-field'>\n"
    s << "       <label>#{label}</label>\n" unless label==false
    s << "       #{content_tag('span', output, tags)}\n"
    s << "    </div>\n"
    s
  end
  
end
