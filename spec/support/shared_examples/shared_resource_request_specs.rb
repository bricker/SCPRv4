##
# Shared examples for managed resources
#
shared_examples_for "managed resource" do |options|
  it_behaves_like "managed resource index", options
  it_behaves_like "managed resource create", options
  it_behaves_like "managed resource update", options
  it_behaves_like "managed resource destroy", options
end

shared_examples_for "managed resource index" do |options|
  before :each do
    login
    valid_record.save!
  end

  describe "Index" do
    it "shows a list of records" do
      visit described_class.admin_index_path

      within('table.index-list') do
        page.should have_css "a.btn"
        first('a.btn').click

        current_path.should eq valid_record.admin_edit_path
      end
    end
  end
end

shared_examples_for "managed resource create" do |options|
  before :each do
    login
    # Touch them so their associations get created
    valid_record
    invalid_record
    updated_record
    @field_options = options ? options.fetch(:field_options, {}) : {}
  end

  #------------------------

  describe "Create" do
    before :each do
      visit described_class.admin_new_path
    end

    context "invalid" do
      it "shows validation errors" do
        if invalid_record
          fill_required_fields(invalid_record, @field_options)
          click_button "edit"
          current_path.should eq described_class.admin_index_path
          described_class.count.should eq 0
          page.should_not have_css ".alert-success"
          page.should have_css ".alert-error"
          page.should have_css ".help-inline"
        end
      end
    end

    context "valid" do
      it "is created" do
        fill_required_fields(valid_record, @field_options)
        click_button "edit"
        described_class.count.should eq 1
        valid = described_class.first
        current_path.should eq valid.admin_edit_path
        page.should have_css ".alert-success"
        page.should_not have_css ".alert-error"
        page.should_not have_css ".help-inline"
        page.should have_css "#edit_#{described_class.singular_route_key}_#{valid.id}"
      end
    end
  end
end

#------------------------

shared_examples_for "managed resource update" do |options|
  before :each do
    login
    # Touch them so their associations get created
    valid_record
    invalid_record
    updated_record
    @field_options = options ? options.fetch(:field_options, {}) : {}
  end

  #------------------------

  describe "Update" do
    before :each do
      valid_record.save!
      visit valid_record.admin_edit_path
    end

    context "invalid" do
      it "shows validation error" do
        if invalid_record
          fill_required_fields(invalid_record, @field_options)
          click_button "edit"
          page.should have_css ".alert-error"
          current_path.should eq valid_record.admin_show_path # Technically "#update" but this'll do
        end
      end
    end

    context "valid" do
      it "updates attributes" do
        fill_required_fields(updated_record, @field_options)
        click_button "edit"
        page.should have_css ".alert-success"
        current_path.should eq valid_record.admin_edit_path
      end
    end
  end
end

#------------------------

shared_examples_for "managed resource destroy" do |options|
  before :each do
    login
    # Touch them so their associations get created
    valid_record
    invalid_record
    updated_record
  end

  describe "Destroy" do
    before :each do
      valid_record.save!
      visit valid_record.admin_edit_path
    end

    it "Deletes the record and redirects to index" do
      click_link "Delete"
      current_path.should eq described_class.admin_index_path
      page.should have_css ".alert-success"
      described_class.count.should eq 0
    end
  end
end

#------------------------

shared_examples_for "save options" do |options|
  describe "Save options" do
    before :each do
      login
      valid_record.save!
      visit valid_record.admin_edit_path
    end

    context "Save" do
      it "returns to the edit page" do
        click_button "edit"
        current_path.should eq valid_record.admin_edit_path
        page.should have_css ".alert-success"
        page.should have_css "form#edit_#{described_class.singular_route_key}_#{valid_record.id}"
      end
    end

    context "Save & Return to List" do
      it "returns to the index page" do
        click_button "index"
        current_path.should eq described_class.admin_index_path
        page.should have_css ".alert-success"
        page.should have_css ".index-header"
      end
    end

    context "Save & Add Another" do
      it "returns to the new page" do
        click_button "new"
        page.should have_css ".alert-success"
        current_path.should eq described_class.admin_new_path
      end
    end
  end
end
