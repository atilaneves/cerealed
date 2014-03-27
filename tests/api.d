module tests.api;

import unit_threaded;
import cerealed;

void testType() {
    checkEqual(new Cerealiser().type, CerealType.Write);
    checkEqual(new Decerealiser([1]).type, CerealType.Read);
}
