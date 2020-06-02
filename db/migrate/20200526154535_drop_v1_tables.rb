class DropV1Tables < ActiveRecord::Migration[5.2]
  def change
    drop_table :delayed_jobs # removed in https://github.com/department-of-veterans-affairs/caseflow-efolder/pull/75
    drop_table :documents # part of v1
    drop_table :downloads # part of v1
    drop_table :searches # part of v1
  end
end
