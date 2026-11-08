Name:           euromillions
Version:        1.0.0
Release:        1%{?dist}
Summary:        Draw EuroMillions grids from the terminal

License:        GPL-3.0-or-later
URL:            https://github.com/alaunay/euromillions
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  bash
BuildRequires:  coreutils
BuildRequires:  gettext
Requires:       bash >= 4
Requires:       coreutils
Requires:       gettext

%description
A small Bash script that draws five numbers from 1 to 50 and two stars
from 1 to 12, sorted, with an optional colour output and translations
through GNU gettext.

%prep
%autosetup -n %{name}-%{version}

%build
tools/build-locales.sh

%install
install -Dm755 euromillions.sh %{buildroot}%{_bindir}/euromillions
install -d %{buildroot}%{_datadir}/%{name}
cp -a locale po %{buildroot}%{_datadir}/%{name}/

%files
%{_bindir}/euromillions
%{_datadir}/%{name}

%changelog
* Sun Nov 08 2026 Arnaud Launay <asl@launay.org> - 1.0.0-1
- Initial package.
