require 'rails_helper'

RSpec.describe Media, type: :model do
  describe 'validations' do
    subject { build(:media) }

    it { is_expected.to validate_presence_of(:filename) }
    it { is_expected.to validate_presence_of(:file_size) }
    it { is_expected.to validate_presence_of(:content_type) }
    it { is_expected.to validate_presence_of(:checksum) }
    it { is_expected.to validate_numericality_of(:file_size).is_greater_than(0) }

    context 'checksum uniqueness' do
      let(:checksum) { Digest::MD5.hexdigest("unique_content") }

      before { create(:media, checksum: checksum) }

      it 'prevents duplicate file upload' do
        duplicate_media = build(:media, checksum: checksum)
        expect(duplicate_media).not_to be_valid
        expect(duplicate_media.errors[:checksum]).to include(
          I18n.t('activerecord.errors.models.media.attributes.checksum.file_already_exists')
        )
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:parser_records).dependent(:nullify) }
  end
end
