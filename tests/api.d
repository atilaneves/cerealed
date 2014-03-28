module tests.api;

import unit_threaded;
import cerealed;

void testType() {
    checkEqual(new OldCerealiser().type, CerealType.WriteBytes);
    checkEqual(new OldDecerealiser([1]).type, CerealType.ReadBytes);
}
