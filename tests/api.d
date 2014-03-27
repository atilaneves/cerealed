module tests.api;

import unit_threaded;
import cerealed;

void testType() {
    checkEqual(new OldCerealiser().type, CerealType.Write);
    checkEqual(new OldDecerealiser([1]).type, CerealType.Read);
}
