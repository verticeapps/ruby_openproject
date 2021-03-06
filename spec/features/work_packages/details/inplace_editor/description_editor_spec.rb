require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'description inplace editor', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let(:property_name) { :description }
  let(:property_title) { 'Description' }
  let(:description_text) { 'Ima description' }
  let!(:work_package) {
    FactoryGirl.create(
      :work_package,
      project: project,
      description: description_text
    )
  }
  let(:user) { FactoryGirl.create :admin }
  let(:field) { WorkPackageTextAreaField.new wp_page, 'description' }
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }

  before do
    login_as(user)

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  context 'with permission' do
    it 'shows the description field' do
      field.expect_state_text(description_text)
    end
  end

  context 'when is empty' do
    let(:description_text) { '' }

    it 'renders a placeholder' do
      field.expect_state_text 'Click to enter description...'

      field.activate!
      field.expect_save_button(enabled: false)
      field.set_value 'A new hope ...'
      field.expect_save_button(enabled: true)
      field.submit_by_click

      wp_page.expect_notification message: I18n.t('js.notice_successful_update')
      field.expect_state_text 'A new hope ...'
    end
  end

  context 'with no permission' do
    let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryGirl.create :role, permissions: %i(view_work_packages) }

    it 'does not show the field' do
      expect(page).to have_no_selector('.wp-edit-field.description.-editable')

      field.trigger_link.click
      field.expect_inactive!
    end

    context 'when is empty' do
      let(:description_text) { '' }

      it 'renders a placeholder' do
        field.expect_state_text ''
      end
    end
  end

  it_behaves_like 'a cancellable field'
end
